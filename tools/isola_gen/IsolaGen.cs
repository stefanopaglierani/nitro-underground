// Generatore dell'isola tropicale (terreno + rete stradale + incisione strade + mesh glb).
// C# 5 (compilato da PowerShell Add-Type). Coordinate: metri, X est, Y sud, Z alto (come Unreal / 100).
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Drawing;
using System.Drawing.Imaging;

public static class IsolaGen
{
    // ---------------- parametri ----------------
    public const double HALF = 4096.0;      // dominio [-4096, 4096] m
    public const double CELL = 2.0;         // griglia altezze 2 m
    public const int N = 4097;
    public static float[] H;                // altezze (m)
    public static float[] H0;               // altezze prima delle strade
    public static byte[] RoadMask;          // 0..255 vicinanza strada (per il materiale)
    public static StringBuilder Log = new StringBuilder();
    static int Seed = 1977;

    // ---------------- rumore ----------------
    static double Hash(int x, int y, int s)
    {
        unchecked
        {
            uint h = (uint)(x * 374761393 + y * 668265263 + s * 2147483647);
            h = (h ^ (h >> 13)) * 1274126177u;
            h ^= h >> 16;
            return (h & 0xFFFFFF) / (double)0xFFFFFF;
        }
    }
    static double Grad(int ix, int iy, double dx, double dy, int s)
    {
        double a = Hash(ix, iy, s) * Math.PI * 2;
        return Math.Cos(a) * dx + Math.Sin(a) * dy;
    }
    static double Fade(double t) { return t * t * t * (t * (t * 6 - 15) + 10); }
    public static double Perlin(double x, double y, int s)
    {
        int x0 = (int)Math.Floor(x), y0 = (int)Math.Floor(y);
        double fx = x - x0, fy = y - y0;
        double u = Fade(fx), v = Fade(fy);
        double n00 = Grad(x0, y0, fx, fy, s), n10 = Grad(x0 + 1, y0, fx - 1, fy, s);
        double n01 = Grad(x0, y0 + 1, fx, fy - 1, s), n11 = Grad(x0 + 1, y0 + 1, fx - 1, fy - 1, s);
        double a = n00 + u * (n10 - n00), b = n01 + u * (n11 - n01);
        return (a + v * (b - a)) * 1.4142;
    }
    public static double Fbm(double x, double y, int oct, int s)
    {
        double sum = 0, amp = 0.5, f = 1;
        for (int i = 0; i < oct; i++) { sum += amp * Perlin(x * f, y * f, s + i * 31); f *= 2.03; amp *= 0.5; }
        return sum;
    }
    public static double Ridged(double x, double y, int oct, int s)
    {
        double sum = 0, amp = 0.5, f = 1, w = 1;
        for (int i = 0; i < oct; i++)
        {
            double n = 1 - Math.Abs(Perlin(x * f, y * f, s + i * 57));
            n *= n * w; w = Math.Min(1, n * 2);
            sum += amp * n; f *= 2.1; amp *= 0.5;
        }
        return sum;
    }
    static double Smooth(double e0, double e1, double x)
    {
        double t = Math.Max(0, Math.Min(1, (x - e0) / (e1 - e0)));
        return t * t * (3 - 2 * t);
    }
    static double Lerp(double a, double b, double t) { return a + (b - a) * t; }

    // ---------------- zone dell'isola ----------------
    public static double PeakX = -450, PeakY = -350;     // vulcano (nord-ovest del centro)
    public static double CityX = 1750, CityY = 1700, CityR = 800;  // citta' (sud-est, pianura costiera)
    public static double VilWX = -2500, VilWY = 1350, VilR = 480;   // villaggio ovest
    public static double VilEX = 2350, VilEY = -1500;               // villaggio est
    public static double CliffAngle = -2.35;   // direzione delle scogliere (nord-ovest)

    static double CoastR(double ang)
    {
        double c = Math.Cos(ang), s = Math.Sin(ang);
        return 3150 + 520 * Fbm(c * 1.0 + 5, s * 1.0 + 5, 5, Seed + 3) + 260 * Fbm(c * 2.6 + 9, s * 2.6, 4, Seed + 7);
    }

    static double BaseHeight(double x, double y)
    {
        // deformazione del dominio forte: baie, promontori, penisole
        double wx = x + 520 * Fbm(x / 1700.0, y / 1700.0, 5, Seed + 11);
        double wy = y + 520 * Fbm(x / 1700.0 + 7.3, y / 1700.0 - 2.1, 5, Seed + 13);
        double r = Math.Sqrt(wx * wx + wy * wy);
        double ang = Math.Atan2(wy, wx);
        double R = CoastR(ang);
        double d = r / R;                          // 1 = linea di costa
        double da = Math.Abs(Math.IEEERemainder(ang - CliffAngle, Math.PI * 2));
        double cliff = 1 - Smooth(0.3, 0.7, da);
        // massiccio vulcanico: cono principale + rilievi secondari
        double dvx = x - PeakX, dvy = y - PeakY;
        double dv = Math.Sqrt(dvx * dvx + dvy * dvy);
        double cone = 640 * Math.Pow(Math.Max(0, 1 - dv / 3100.0), 1.55);
        double sec = 260 * Math.Pow(Math.Max(0, 1 - Dist(x, y, -1500, -1500) / 1500.0), 1.6)
                   + 200 * Math.Pow(Math.Max(0, 1 - Dist(x, y, 600, -1700) / 1300.0), 1.6);
        double massif = Math.Max(cone, sec) + 0.35 * Math.Min(cone, sec);
        if (dv < 380) massif -= 55 * Math.Pow(1 - dv / 380.0, 1.5);   // caldera
        // erosione: creste e valli in coordinate polari deformate (rami irregolari, non a stella)
        double pa = Math.Atan2(dvy, dvx);
        double logr = Math.Log(dv + 120);
        double pu = pa * 2.0 + 0.7 * Fbm(dvx / 1500.0, dvy / 1500.0, 3, Seed + 17);
        double pv = logr * 1.1;
        double gul = Ridged(Math.Cos(pu) * 1.3 + pv * 0.2, Math.Sin(pu) * 1.3 + pv, 4, Seed + 19);
        double crest = Ridged(x / 900.0 + 3.1, y / 900.0, 5, Seed + 41);
        double gulW = Smooth(700, 1500, dv);
        double erosion = 0.62 + 0.28 * crest + 0.22 * gul * gulW - 0.08 * gulW;
        double hillT = Smooth(0.0, 0.25, massif / 640.0) * Smooth(200, 1100, dv);   // niente erosione violenta in vetta
        double land = massif * Lerp(1.0, erosion, hillT);
        land += 28 * Smooth(1.0, 0.6, d) + 30 * Fbm(x / 700.0, y / 700.0, 5, Seed + 23) * Smooth(1.0, 0.85, d);
        // scogliere tipo Na Pali: pareti scanalate subito dietro la costa
        double flutes = 0.75 + 0.35 * Ridged(Math.Cos(ang) * 14 + x / 650.0, Math.Sin(ang) * 14 + y / 650.0, 3, Seed + 29);
        land += cliff * 240 * Smooth(0.995, 0.86, d) * Smooth(0.45, 0.75, d) * flutes;   // solo fascia costiera
        // pianure (citta' e villaggi): rampa dolce dalla costa
        double inland = Math.Max(0, (1 - d) * R);
        double plainH = 2.6 + 0.028 * inland + 3 * Fbm(x / 500.0, y / 500.0, 3, Seed + 31);
        double cm = Smooth(CityR * 1.25, CityR * 0.7, Dist(x, y, CityX, CityY));
        double vw = Smooth(VilR * 1.5, VilR * 0.7, Dist(x, y, VilWX, VilWY));
        double ve = Smooth(VilR * 1.5, VilR * 0.7, Dist(x, y, VilEX, VilEY));
        double pm = Math.Max(cm, Math.Max(vw, ve)) * (1 - cliff);
        land = Lerp(land, Math.Min(land, plainH + 5 * Math.Max(vw, ve)), pm);
        // fascia costiera: spiaggia bassa (fuori dalle scogliere)
        double shore = Smooth(1.0, 0.978, d);
        double beachH = 0.6 + (1 - d) * 110;
        land = Lerp(Lerp(beachH, land, cliff), land, shore);
        if (d < 1.0) return Math.Max(land, 0.35 + 3 * cliff);
        // mare: barriera e laguna a sud-est, poi fondale profondo
        double reefSide = Smooth(-0.2, 0.7, Math.Cos(ang - 0.85));
        double floor = -1.5 - 50 * Smooth(1.0, 1.5, d) - 25 * cliff * Smooth(1.0, 1.06, d);
        double reef = reefSide * Math.Exp(-Math.Pow((d - 1.10) / 0.016, 2)) * (Math.Min(-0.7, floor + 30) - floor) * (0.6 + 0.4 * Fbm(x / 200.0, y / 200.0, 2, Seed + 51));
        double lagoon = reefSide * Smooth(1.0, 1.025, d) * (1 - Smooth(1.08, 1.105, d)) * -2.0;
        return floor + Math.Max(0, reef) + lagoon;
    }    static double Dist(double x, double y, double a, double b) { return Math.Sqrt((x - a) * (x - a) + (y - b) * (y - b)); }

    public static double X(int i) { return -HALF + i * CELL; }
    public static int Idx(int i, int j) { return j * N + i; }
    public static double Sample(double x, double y)
    {
        double fx = (x + HALF) / CELL, fy = (y + HALF) / CELL;
        int i = (int)Math.Floor(fx), j = (int)Math.Floor(fy);
        if (i < 0) i = 0; if (j < 0) j = 0; if (i > N - 2) i = N - 2; if (j > N - 2) j = N - 2;
        double tx = fx - i, ty = fy - j;
        double a = H[Idx(i, j)], b = H[Idx(i + 1, j)], c = H[Idx(i, j + 1)], e = H[Idx(i + 1, j + 1)];
        return Lerp(Lerp(a, b, tx), Lerp(c, e, tx), ty);
    }

    public static void BuildTerrain(int seed)
    {
        Seed = seed;
        H = new float[N * N];
        System.Threading.Tasks.Parallel.For(0, N, j =>
        {
            for (int i = 0; i < N; i++) H[Idx(i, j)] = (float)BaseHeight(X(i), X(j));
        });
        // fiume: dalla valle sopra la citta' al mare

        Thermal(1.15, 40);   // frana naturale: niente pareti oltre ~49 gradi
        Blur(H, 3);
        H0 = (float[])H.Clone();
        Log.AppendLine("terreno generato");
    }

    static void CarveRiver(double[] p)
    {
        List<double[]> pts = Resample(ToPts(p), 4);
        double top = Sample(pts[0][0], pts[0][1]);
        for (int k = 0; k < pts.Count; k++)
        {
            double t = k / (double)(pts.Count - 1);
            double target = Lerp(Math.Min(top, 90), -1.5, Math.Pow(t, 0.8));
            double w = Lerp(8, 22, t);
            Stamp(pts[k][0], pts[k][1], w, w * 4, target, true);
        }
    }
    static List<double[]> ToPts(double[] p)
    {
        var l = new List<double[]>();
        for (int i = 0; i + 1 < p.Length; i += 2) l.Add(new double[] { p[i], p[i + 1] });
        return l;
    }
    static void Stamp(double x, double y, double inner, double outer, double target, bool onlyLower)
    {
        int r = (int)Math.Ceiling(outer / CELL) + 1;
        int ci = (int)Math.Round((x + HALF) / CELL), cj = (int)Math.Round((y + HALF) / CELL);
        for (int j = cj - r; j <= cj + r; j++)
            for (int i = ci - r; i <= ci + r; i++)
            {
                if (i < 0 || j < 0 || i >= N || j >= N) continue;
                double d = Dist(X(i), X(j), x, y);
                if (d > outer) continue;
                double w = d <= inner ? 1 : Smooth(outer, inner, d);
                int id = Idx(i, j);
                double nh = Lerp(H[id], target, w);
                if (!onlyLower || nh < H[id]) H[id] = (float)nh;
            }
    }

    // erosione termica: dove la pendenza supera "talus" (dislivello/distanza) il materiale scivola verso il basso
    static void Thermal(double talus, int iters)
    {
        float lim = (float)(talus * CELL);
        float[] mv = new float[H.Length];
        int[] tg = new int[H.Length];
        for (int it = 0; it < iters; it++)
        {
            System.Threading.Tasks.Parallel.For(1, N - 1, j =>
            {
                for (int i = 1; i < N - 1; i++)
                {
                    int id = Idx(i, j);
                    float h = H[id];
                    float maxd = 0; int tgt = -1;
                    float dd;
                    dd = h - H[id - 1]; if (dd > maxd) { maxd = dd; tgt = id - 1; }
                    dd = h - H[id + 1]; if (dd > maxd) { maxd = dd; tgt = id + 1; }
                    dd = h - H[id - N]; if (dd > maxd) { maxd = dd; tgt = id - N; }
                    dd = h - H[id + N]; if (dd > maxd) { maxd = dd; tgt = id + N; }
                    if (tgt >= 0 && maxd > lim) { mv[id] = (maxd - lim) * 0.25f; tg[id] = tgt; } else { mv[id] = 0; tg[id] = -1; }
                }
            });
            for (int k = 0; k < H.Length; k++) if (mv[k] > 0) { H[k] -= mv[k]; H[tg[k]] += mv[k]; }
        }
    }

    static void Blur(float[] a, int passes)
    {
        float[] t = new float[a.Length];
        for (int p = 0; p < passes; p++)
        {
            System.Threading.Tasks.Parallel.For(0, N, j =>
            {
                for (int i = 0; i < N; i++)
                {
                    double s = 0; int c = 0;
                    for (int dj = -1; dj <= 1; dj++) for (int di = -1; di <= 1; di++)
                        {
                            int ii = i + di, jj = j + dj;
                            if (ii < 0 || jj < 0 || ii >= N || jj >= N) continue;
                            s += a[Idx(ii, jj)]; c++;
                        }
                    t[Idx(i, j)] = (float)(s / c);
                }
            });
            Array.Copy(t, a, a.Length);
        }
    }

    // ---------------- strade ----------------
    public class Road
    {
        public string Name; public string Kind; public double Width; public double MaxGrade; public bool Closed;
        public List<double[]> P = new List<double[]>();   // x, y, z (z = profilo)
    }
    public static List<Road> Roads = new List<Road>();

    // A* su griglia 8 m con 16 direzioni; costo con penalita' di pendenza
    const double AC = 8.0;
    const int AN = 1025;
    static float[] HA;
    static void PrepA()
    {
        HA = new float[AN * AN];
        for (int j = 0; j < AN; j++) for (int i = 0; i < AN; i++) HA[j * AN + i] = (float)Sample(-HALF + i * AC, -HALF + j * AC);
    }
    static readonly int[] DI = { 1, 1, 0, -1, -1, -1, 0, 1, 2, 1, -1, -2, -2, -1, 1, 2 };
    static readonly int[] DJ = { 0, 1, 1, 1, 0, -1, -1, -1, 1, 2, 2, 1, -1, -2, -2, -1 };
    public static List<double[]> AStar(double x0, double y0, double x1, double y1, double maxGrade, float[] extraCost)
    {
        int si = (int)Math.Round((x0 + HALF) / AC), sj = (int)Math.Round((y0 + HALF) / AC);
        int ti = (int)Math.Round((x1 + HALF) / AC), tj = (int)Math.Round((y1 + HALF) / AC);
        int total = AN * AN;
        float[] g = new float[total];
        int[] from = new int[total];
        bool[] closed = new bool[total];
        for (int k = 0; k < total; k++) { g[k] = float.MaxValue; from[k] = -1; }
        var open = new SortedSet<long>();
        int s = sj * AN + si, t = tj * AN + ti;
        g[s] = 0;
        Func<int, double> heur = k => { int i = k % AN, j = k / AN; return Math.Sqrt((i - ti) * (i - ti) + (j - tj) * (j - tj)) * AC; };
        open.Add(((long)(heur(s) * 16) << 22) + s);
        int iter = 0;
        while (open.Count > 0)
        {
            long top = open.Min; open.Remove(top);
            int cur = (int)(top & 0x3FFFFF);
            if (closed[cur]) continue;
            closed[cur] = true;
            if (cur == t) break;
            if (++iter > 2500000) break;
            int ci = cur % AN, cj = cur / AN;
            for (int k = 0; k < 16; k++)
            {
                int ni = ci + DI[k], nj = cj + DJ[k];
                if (ni < 1 || nj < 1 || ni >= AN - 1 || nj >= AN - 1) continue;
                int nb = nj * AN + ni;
                if (closed[nb]) continue;
                double h1 = HA[cur], h2 = HA[nb];
                bool wet = h2 < 0.7;
                double len = Math.Sqrt(DI[k] * DI[k] + DJ[k] * DJ[k]) * AC;
                double grade = Math.Abs(h2 - h1) / len;
                double c = len * (1 + 30 * grade * grade);
                if (grade > maxGrade * WallFactor) continue;   // pareti: non attraversabili
                if (grade > maxGrade) c *= 1 + 60 * (grade - maxGrade) / maxGrade;
                if (extraCost != null) c *= extraCost[nb];
                if (wet) c *= 40;
                double ng = g[cur] + c;
                if (ng < g[nb])
                {
                    g[nb] = (float)ng; from[nb] = cur;
                    open.Add(((long)((ng + heur(nb)) * 16) << 22) + nb);
                }
            }
        }
        var path = new List<double[]>();
        if (from[t] < 0 && t != s) return path;
        int c2 = t;
        while (c2 >= 0) { path.Add(new double[] { -HALF + (c2 % AN) * AC, -HALF + (c2 / AN) * AC }); if (c2 == s) break; c2 = from[c2]; }
        path.Reverse();
        path[0] = new double[] { x0, y0 }; path[path.Count - 1] = new double[] { x1, y1 };
        return path;
    }

    public static List<double[]> Chaikin(List<double[]> p, int it, bool closed)
    {
        for (int k = 0; k < it; k++)
        {
            var q = new List<double[]>();
            int n = p.Count;
            if (!closed) q.Add(p[0]);
            for (int i = 0; i < (closed ? n : n - 1); i++)
            {
                double[] a = p[i], b = p[(i + 1) % n];
                q.Add(new double[] { a[0] * 0.75 + b[0] * 0.25, a[1] * 0.75 + b[1] * 0.25 });
                q.Add(new double[] { a[0] * 0.25 + b[0] * 0.75, a[1] * 0.25 + b[1] * 0.75 });
            }
            if (!closed) q.Add(p[n - 1]);
            p = q;
        }
        return p;
    }
    public static List<double[]> Resample(List<double[]> p, double step)
    {
        var o = new List<double[]>();
        o.Add(new double[] { p[0][0], p[0][1] });
        double carry = 0;
        for (int i = 0; i + 1 < p.Count; i++)
        {
            double ax = p[i][0], ay = p[i][1], bx = p[i + 1][0], by = p[i + 1][1];
            double L = Dist(ax, ay, bx, by);
            double s = step - carry;
            while (s <= L) { double t = s / L; o.Add(new double[] { ax + (bx - ax) * t, ay + (by - ay) * t }); s += step; }
            carry = L - (s - step);
        }
        var last = p[p.Count - 1];
        if (Dist(o[o.Count - 1][0], o[o.Count - 1][1], last[0], last[1]) > step * 0.3) o.Add(new double[] { last[0], last[1] });
        return o;
    }

    public static Road AddRoad(string name, string kind, double width, double maxGrade, bool closed, List<double[]> pts, int chaikin)
    {
        var r = new Road(); r.Name = name; r.Kind = kind; r.Width = width; r.MaxGrade = maxGrade; r.Closed = closed;
        var sm = Chaikin(pts, chaikin, closed);
        if (closed) sm.Add(new double[] { sm[0][0], sm[0][1] });
        foreach (var q in Resample(sm, 2.0)) r.P.Add(new double[] { q[0], q[1], 0 });
        Roads.Add(r);
        return r;
    }

    public static int Belvederi = 0;
    // trova i tratti "vai e torna" (andata e ritorno quasi sovrapposti, oltre 300 m): li toglie dalla strada e li
    // rimette come strada senza uscita + piazzola belvedere larga 20 m in fondo. I tornanti (tratti corti) restano.
    static void ExtractSpurs(Road r)
    {
        var P = r.P; int n = P.Count;
        for (int i = 0; i < n; i++)
        {
            int best = -1;
            for (int j = i + 20; j < Math.Min(n, i + n / 3); j++) if (Dist(P[i][0], P[i][1], P[j][0], P[j][1]) < 10) best = j;
            if (best < 0) continue;
            double len = 0; for (int k = i; k < best; k++) len += Dist(P[k][0], P[k][1], P[k + 1][0], P[k + 1][1]);
            if (len < 300) { i = best; continue; }
            int apex = i; double far = 0;
            for (int k = i; k <= best; k++) { double d = Dist(P[i][0], P[i][1], P[k][0], P[k][1]); if (d > far) { far = d; apex = k; } }
            int over = 0, tot = 0;
            for (int k = i; k <= apex; k += 2)
            {
                double m = 1e9;
                for (int q = apex; q <= best; q += 2) m = Math.Min(m, Dist(P[k][0], P[k][1], P[q][0], P[q][1]));
                tot++; if (m < 15) over++;
            }
            if (over < tot * 0.6) { i = best; continue; }
            // strada senza uscita: l'andata, fino al punto piu' lontano
            var spur = new List<double[]>();
            for (int k = i; k <= apex; k++) spur.Add(new double[] { P[k][0], P[k][1] });
            Belvederi++;
            string nm = "Belvedere_" + Belvederi;
            AddRoad(nm, "montagna", 6.5, r.MaxGrade, false, spur, 1);
            // piazzola: 24 m lungo l'ultima direzione, finisce 4 m oltre la fine della strada
            int a0 = Math.Max(i, apex - 6);
            double dx = P[apex][0] - P[a0][0], dy = P[apex][1] - P[a0][1], dl = Math.Sqrt(dx * dx + dy * dy); if (dl < 1e-6) dl = 1;
            dx /= dl; dy /= dl;
            var pz = new List<double[]>();
            for (int q = -10; q <= 2; q++) pz.Add(new double[] { P[apex][0] + dx * q * 2, P[apex][1] + dy * q * 2 });
            AddRoad("Piazzola_" + nm, "piazzola", 20, 0.06, false, pz, 0);
            Log.AppendLine(nm + ": tolto dall'anello un vai-e-torna di " + len.ToString("F0") + " m, belvedere a " + P[apex][0].ToString("F0") + "," + P[apex][1].ToString("F0"));
            // l'anello salta il tratto
            P.RemoveRange(i + 1, best - i);
            n = P.Count;
        }
    }

    // percorso A* attraverso una sequenza di punti; se un tratto e' impossibile la strada si interrompe (niente rette)
    public static double WallFactor = 3.5;
    public static List<List<double[]>> RouteParts(List<double[]> wps, double maxGrade, bool closed, float[] extra)
    {
        var parts = new List<List<double[]>>();
        var all = new List<double[]>();
        int n = wps.Count;
        bool anyFail = false;
        for (int k = 0; k < (closed ? n : n - 1); k++)
        {
            var a = wps[k]; var b = wps[(k + 1) % n];
            var seg = AStar(a[0], a[1], b[0], b[1], maxGrade, extra);
            if (seg.Count == 0) { WallFactor = 6; seg = AStar(a[0], a[1], b[0], b[1], maxGrade * 1.2, extra); WallFactor = 3.5; }
            if (seg.Count == 0)
            {
                Log.AppendLine("tratto impossibile, strada interrotta vicino a " + a[0].ToString("F0") + "," + a[1].ToString("F0"));
                anyFail = true;
                if (all.Count > 1) parts.Add(all);
                all = new List<double[]>();
                continue;
            }
            if (all.Count > 0) seg.RemoveAt(0);
            all.AddRange(seg);
        }
        if (all.Count > 1) parts.Add(all);
        var res = new List<List<double[]>>();
        bool stillClosed = closed && !anyFail && parts.Count == 1;
        foreach (var p in parts)
        {
            if (stillClosed) p.RemoveAt(p.Count - 1);
            res.Add(Simplify(p, stillClosed));
        }
        return res;
    }
    public static int SimpStep = 5, SimpWin = 2;
    static List<double[]> Simplify(List<double[]> all, bool closed)
    {
        var simp = new List<double[]>();
        for (int i = 0; i < all.Count; i += SimpStep) simp.Add(all[i]);
        if (!closed) simp.Add(all[all.Count - 1]);
        var avg = new List<double[]>();
        int m = simp.Count;
        for (int i = 0; i < m; i++)
        {
            if (!closed && (i == 0 || i == m - 1)) { avg.Add(simp[i]); continue; }
            double sx = 0, sy = 0; int c = 0;
            for (int q = -SimpWin; q <= SimpWin; q++)
            {
                int k = i + q;
                if (closed) k = ((k % m) + m) % m; else if (k < 0 || k >= m) continue;
                double wq = SimpWin + 1 - Math.Abs(q); sx += simp[k][0] * wq; sy += simp[k][1] * wq; c += (int)wq;
            }
            avg.Add(new double[] { sx / c, sy / c });
        }
        return avg;
    }
    // rende costoso correre affiancati a strade esistenti (si incrociano invece di sovrapporsi)
    static void MarkRoads(float[] extra)
    {
        foreach (var r in Roads)
            for (int k = 0; k < r.P.Count; k += 3)
            {
                int ci = (int)Math.Round((r.P[k][0] + HALF) / AC), cj = (int)Math.Round((r.P[k][1] + HALF) / AC);
                for (int dj = -3; dj <= 3; dj++) for (int di = -3; di <= 3; di++)
                    {
                        int i = ci + di, j = cj + dj;
                        if (i < 0 || j < 0 || i >= AN || j >= AN) continue;
                        extra[j * AN + i] = 5f;
                    }
            }
    }
    public static void AddRouted(string name, string kind, double width, double maxGrade, bool closed, List<double[]> wps, float[] extra)
    {
        bool twisty = kind == "montagna" || kind == "sterrata" || maxGrade > 0.105;
        SimpStep = twisty ? 2 : 4; SimpWin = twisty ? 1 : 2;
        var parts = RouteParts(wps, maxGrade * 0.95, closed, extra);
        bool cl = closed && parts.Count == 1;
        for (int i = 0; i < parts.Count; i++)
            if (parts[i].Count >= 3) AddRoad(parts.Count == 1 ? name : name + "_" + (i + 1), kind, width, maxGrade, cl, parts[i], twisty ? 2 : 3);
    }
    // punto sulla curva di livello: lungo il raggio dal vulcano/centro, dove l'altezza vale target
    public static double[] ContourPoint(double ang, double target, double cx, double cy, double rmin, double rmax)
    {
        double best = rmax, bestErr = 1e9;
        for (double r = rmin; r <= rmax; r += 8)
        {
            double x = cx + Math.Cos(ang) * r, y = cy + Math.Sin(ang) * r;
            double h = Sample(x, y);
            double e = Math.Abs(h - target);
            if (h > 1.5 && e < bestErr) { bestErr = e; best = r; }
        }
        return new double[] { cx + Math.Cos(ang) * best, cy + Math.Sin(ang) * best };
    }
    // punto a una certa distanza dalla costa verso l'interno lungo il raggio
    public static double[] InlandPoint(double ang, double inland)
    {
        double rc = 0;
        for (double r = 200; r < 4090; r += 4)
        {
            if (Sample(Math.Cos(ang) * r, Math.Sin(ang) * r) < 0.6) { rc = r; break; }
        }
        double rr = rc - inland;
        return new double[] { Math.Cos(ang) * rr, Math.Sin(ang) * rr };
    }

    public static void BuildRoads()
    {
        PrepA();
        Roads.Clear();
        _majorMap = null; Belvederi = 0; Raccordi = 0; GridCuts = 0; GridTees = 0;
        float[] extra = new float[AN * AN];
        for (int k = 0; k < extra.Length; k++) extra[k] = 1f;
        // 1) anello costiero (nelle scogliere passa piu' in alto, all'interno)
        // (come a Kauai: sulle scogliere Na Pali la costiera non passa, finisce a due belvedere)
        var ring = new List<double[]>();
        for (int a = 0; a < 26; a++)
        {
            double ang = CliffAngle + 0.62 + a * (Math.PI * 2 - 1.24) / 25;
            ring.Add(InlandPoint(ang, a == 0 || a == 25 ? 260 : 170));
        }
        AddRouted("Strada_Costiera", "statale", 9, 0.10, false, ring, extra);
        // 2) anello di montagna (curva di livello ~230 m attorno al vulcano)
        var mring = new List<double[]>();
        for (int a = 0; a < 14; a++) { double ang = -Math.PI + a * Math.PI * 2 / 14; mring.Add(ContourPoint(ang, 230, PeakX, PeakY, 500, 3200)); }
        MarkRoads(extra);
        AddRouted("Anello_Montagna", "montagna", 7, 0.10, true, mring, extra);
        // 2b) (v0.32, Stefano 22/11/2026) le "matasse": dove l'anello andava in fondo a una valle e tornava indietro
        // sulla stessa strada, l'anello ora tira dritto e il tratto diventa una strada senza uscita con un belvedere
        foreach (var r in Roads.ToArray()) if (r.Name.StartsWith("Anello_Montagna")) ExtractSpurs(r);
        // 3) strada del vulcano (tornanti fino al bordo del cratere)
        var vp = ContourPoint(2.2, 230, PeakX, PeakY, 500, 3200);
        var rim = new double[] { PeakX + 330, PeakY + 180 };
        AddRouted("Strada_Vulcano", "montagna", 6.5, 0.12, false, new List<double[]> { vp, rim }, extra);
        // 4) statale trasversale citta' -> villaggio ovest (passa la sella)
        AddRouted("Statale_Trasversale", "statale", 9, 0.10, false, new List<double[]> { new double[] { CityX - 300, CityY - 200 }, new double[] { 300, 900 }, new double[] { VilWX + 150, VilWY - 100 } }, extra);
        MarkRoads(extra);
        // 5) radiali tra i due anelli
        double[] rad = { -2.8, -2.0, -1.2, -0.4, 0.4, 1.3, 2.0, 2.7 };
        int ri = 0;
        foreach (double ang in rad)
        {
            var a = InlandPoint(ang, 200); var b = ContourPoint(ang + 0.15, 230, PeakX, PeakY, 500, 3200);
            AddRouted("Radiale_" + (++ri), "secondaria", 6.5, 0.10, false, new List<double[]> { a, b }, extra);
        }
        // 6) collegamenti dei villaggi
        AddRouted("Via_Villaggio_Est", "secondaria", 6.5, 0.10, false, new List<double[]> { new double[] { VilEX, VilEY }, ContourPoint(-0.7, 230, PeakX, PeakY, 500, 3200) }, extra);
        MarkRoads(extra);
        // 7) sterrate di collegamento casuali (creano anelli)
        var rnd = new Random(77);
        for (int k = 0; k < 14; k++)
        {
            double a1 = rnd.NextDouble() * Math.PI * 2 - Math.PI;
            double a2 = a1 + 0.5 + rnd.NextDouble() * 0.9;
            var p1 = InlandPoint(a1, 300 + rnd.NextDouble() * 500);
            var p2 = InlandPoint(a2, 300 + rnd.NextDouble() * 700);
            if (Sample(p1[0], p1[1]) < 2 || Sample(p2[0], p2[1]) < 2) continue;
            double m1 = Math.Abs(Math.IEEERemainder(a1 - CliffAngle, Math.PI * 2)), m2 = Math.Abs(Math.IEEERemainder(a2 - CliffAngle, Math.PI * 2));
            if (m1 < 0.7 || m2 < 0.7) continue;
            AddRouted("Sterrata_" + (k + 1), "sterrata", 4.5, 0.12, false, new List<double[]> { p1, p2 }, extra);
        }
        // 7b) (v0.32, Stefano 22/11/2026) le statali e le secondarie che finiscono nel nulla si ricollegano alla strada piu' vicina
        ConnectDeadEnds(extra);
        // 8) griglia della citta' e dei villaggi
        Grid("Citta", CityX, CityY, CityR * 0.8, 0.26, 120, 100, 10, "citta");
        Grid("VillaggioOvest", VilWX, VilWY, VilR * 0.8, -0.4, 90, 80, 6.5, "villaggio");
        Grid("VillaggioEst", VilEX, VilEY, VilR * 0.8, 0.7, 90, 80, 6.5, "villaggio");
        Log.AppendLine("strade: " + Roads.Count + ", belvederi " + Belvederi + ", raccordi " + Raccordi + ", vie tagliate " + GridCuts + ", incroci a T " + GridTees);
    }

    // ---- capi liberi: statali e secondarie che finiscono senza toccare un'altra strada ----
    // (fuori da citta' e villaggi: li' la strada entra nella griglia delle vie)
    public static int Raccordi = 0;
    static void ConnectDeadEnds(float[] extra)
    {
        var majors = new List<Road>(Roads);
        foreach (var r in majors)
        {
            if (r.Closed || (r.Kind != "statale" && r.Kind != "secondaria")) continue;
            for (int e = 0; e < 2; e++)
            {
                var p = e == 0 ? r.P[0] : r.P[r.P.Count - 1];
                if (Dist(p[0], p[1], CityX, CityY) < CityR || Dist(p[0], p[1], VilWX, VilWY) < VilR || Dist(p[0], p[1], VilEX, VilEY) < VilR) continue;
                double best = 1e9; double[] q = null;
                foreach (var o in Roads)
                {
                    if (o == r) continue;
                    foreach (var op in o.P)
                    {
                        double d = Dist(p[0], p[1], op[0], op[1]);
                        if (d < best) { best = d; q = op; }
                    }
                }
                if (q == null || best < (r.Width * 0.5 + 4) || best > 2500) continue;   // gia' collegata, o troppo lontana
                var path = AStar(p[0], p[1], q[0], q[1], r.MaxGrade, extra);
                if (path.Count < 2) { Log.AppendLine("raccordo impossibile per " + r.Name); continue; }
                bool twisty = r.MaxGrade > 0.105;
                SimpStep = 2; SimpWin = 1;
                var simp = Simplify(path, false);
                if (simp.Count < 3) simp = path;
                AddRoad("Raccordo_" + r.Name + "_" + e, r.Kind, r.Width, r.MaxGrade, false, simp, twisty ? 2 : 3);
                Raccordi++;
                Log.AppendLine("raccordo " + r.Name + " (" + (e == 0 ? "inizio" : "fine") + "): " + best.ToString("F0") + " m in linea d'aria");
            }
        }
    }

    static void Grid(string name, double cx, double cy, double rad, double rot, double bx, double by, double w, string kind)
    {
        double c = Math.Cos(rot), s = Math.Sin(rot);
        int nx = (int)(rad * 2 / bx), ny = (int)(rad * 2 / by);
        // vie lungo x
        for (int j = 0; j <= ny; j++)
        {
            double v = -rad + j * by;
            var seg = new List<double[]>();
            for (double u = -rad; u <= rad; u += 10)
            {
                double x = cx + u * c - v * s, y = cy + u * s + v * c;
                bool ok = Dist(x, y, cx, cy) < rad && Sample(x, y) > 1.8;
                if (ok) seg.Add(new double[] { x, y });
                else if (seg.Count > 0) { Flush(name + "_A" + j, kind, w, seg); seg = new List<double[]>(); }
            }
            Flush(name + "_A" + j, kind, w, seg);
        }
        for (int i = 0; i <= nx; i++)
        {
            double u = -rad + i * bx;
            var seg = new List<double[]>();
            for (double v = -rad; v <= rad; v += 10)
            {
                double x = cx + u * c - v * s, y = cy + u * s + v * c;
                bool ok = Dist(x, y, cx, cy) < rad && Sample(x, y) > 1.8;
                if (ok) seg.Add(new double[] { x, y });
                else if (seg.Count > 0) { Flush(name + "_B" + i, kind, w, seg); seg = new List<double[]>(); }
            }
            Flush(name + "_B" + i, kind, w, seg);
        }
    }
    // (v0.32, Stefano 22/11/2026) le vie di citta' e villaggi non si intrecciano con le strade principali:
    // dove ne passa una, il tratto di via si toglie; i pezzi rimasti si attaccano alla strada principale
    // con un incrocio a T, se l'angolo e' sensato (almeno 35 gradi), altrimenti finiscono prima.
    public static int GridCuts = 0, GridTees = 0;
    static Dictionary<long, List<double[]>> _majorMap;   // x, y, meta' larghezza, direzione x, direzione y
    static void BuildMajorMap()
    {
        _majorMap = new Dictionary<long, List<double[]>>();
        foreach (var o in Roads)
        {
            if (o.Kind == "citta" || o.Kind == "villaggio") continue;
            int n = o.P.Count;
            for (int k = 0; k < n; k++)
            {
                var q = o.P[k];
                var a = o.P[Math.Max(0, k - 1)]; var b = o.P[Math.Min(n - 1, k + 1)];
                double dx = b[0] - a[0], dy = b[1] - a[1], dl = Math.Max(1e-6, Math.Sqrt(dx * dx + dy * dy));
                long key = ((long)Math.Floor((q[0] + HALF) / 16) << 20) + (long)Math.Floor((q[1] + HALF) / 16);
                List<double[]> l; if (!_majorMap.TryGetValue(key, out l)) { l = new List<double[]>(); _majorMap[key] = l; }
                l.Add(new double[] { q[0], q[1], o.Width * 0.5, dx / dl, dy / dl });
            }
        }
    }
    // la strada principale piu' vicina: [x, y, meta' larghezza, distanza, direzione x, direzione y]
    static double[] NearestMajor(double x, double y)
    {
        if (_majorMap == null) BuildMajorMap();
        long cx = (long)Math.Floor((x + HALF) / 16), cy = (long)Math.Floor((y + HALF) / 16);
        double[] best = null; double bd = 1e9;
        for (long dx = -2; dx <= 2; dx++) for (long dy = -2; dy <= 2; dy++)
            {
                List<double[]> l; if (!_majorMap.TryGetValue(((cx + dx) << 20) + cy + dy, out l)) continue;
                foreach (var q in l) { double d = Dist(x, y, q[0], q[1]); if (d < bd) { bd = d; best = q; } }
            }
        return best == null ? null : new double[] { best[0], best[1], best[2], bd, best[3], best[4] };
    }
    static void Flush(string name, string kind, double w, List<double[]> seg)
    {
        if (seg.Count < 2) return;
        int n = seg.Count;
        var near = new double[n][];
        var bad = new bool[n];
        for (int i = 0; i < n; i++)
        {
            near[i] = NearestMajor(seg[i][0], seg[i][1]);
            bad[i] = near[i] != null && near[i][3] < near[i][2] + w * 0.5 + 5;
        }
        int a = 0;
        while (a < n)
        {
            if (bad[a]) { a++; continue; }
            int b = a;
            while (b + 1 < n && !bad[b + 1]) b++;
            var piece = new List<double[]>();
            if (a > 0) AddTee(piece, seg, a, a - 1, near[a - 1], true);
            for (int i = a; i <= b; i++) piece.Add(seg[i]);
            if (b < n - 1) AddTee(piece, seg, b, b + 1, near[b + 1], false);
            if (a > 0 || b < n - 1) GridCuts++;
            if (piece.Count >= 3) AddRoad(name + "_" + Roads.Count, kind, w, 0.12, false, piece, 0);
            a = b + 1;
        }
    }
    // attacca il capo della via (seg[keep]) al punto della strada principale accanto (m), se l'angolo va bene
    static void AddTee(List<double[]> piece, List<double[]> seg, int keep, int gone, double[] m, bool atStart)
    {
        if (m == null) return;
        double sx = seg[gone][0] - seg[keep][0], sy = seg[gone][1] - seg[keep][1];   // verso della via
        double mx = m[0] - seg[keep][0], my = m[1] - seg[keep][1];
        double ls = Math.Sqrt(sx * sx + sy * sy), lm = Math.Sqrt(mx * mx + my * my);
        if (ls < 1e-6 || lm < 1e-6 || lm > 40) return;
        // angolo tra la via e la strada principale nel punto d'incontro
        double ang = Math.Acos(Math.Min(1, Math.Abs(m[4] * sx + m[5] * sy) / ls)) * 180 / Math.PI;
        if (ang < 35) return;
        var pt = new double[] { m[0], m[1] };
        if (atStart) piece.Insert(0, pt); else piece.Add(pt);
        GridTees++;
    }

    // ---- incroci: coppie (strada A, indice, strada B, indice) dove due strade si toccano
    public class Junction { public Road A; public int KA; public Road B; public int KB; public double Z; }
    public static List<Junction> Junctions = new List<Junction>();
    public static void FindJunctions()
    {
        Junctions.Clear();
        // griglia spaziale 16 m
        var cellMap = new Dictionary<long, List<int[]>>();
        for (int ri = 0; ri < Roads.Count; ri++)
            for (int k = 0; k < Roads[ri].P.Count; k += 2)
            {
                long key = ((long)Math.Floor((Roads[ri].P[k][0] + HALF) / 16) << 20) + (long)Math.Floor((Roads[ri].P[k][1] + HALF) / 16);
                List<int[]> l; if (!cellMap.TryGetValue(key, out l)) { l = new List<int[]>(); cellMap[key] = l; }
                l.Add(new int[] { ri, k });
            }
        var seen = new HashSet<long>();
        for (int ri = 0; ri < Roads.Count; ri++)
        {
            var r = Roads[ri];
            for (int k = 0; k < r.P.Count; k += 2)
            {
                long cx = (long)Math.Floor((r.P[k][0] + HALF) / 16), cy = (long)Math.Floor((r.P[k][1] + HALF) / 16);
                for (long dx = -1; dx <= 1; dx++) for (long dy = -1; dy <= 1; dy++)
                    {
                        List<int[]> l; if (!cellMap.TryGetValue(((cx + dx) << 20) + cy + dy, out l)) continue;
                        foreach (var e in l)
                        {
                            if (e[0] <= ri) continue;
                            var o = Roads[e[0]];
                            double lim = (r.Width + o.Width) * 0.5;
                            if (Dist(r.P[k][0], r.P[k][1], o.P[e[1]][0], o.P[e[1]][1]) > lim * 0.6) continue;
                            long sk = ((long)ri * 1000 + e[0]) * 100000 + (k / 30);
                            if (seen.Contains(sk)) continue;
                            seen.Add(sk);
                            var j = new Junction(); j.A = r; j.KA = k; j.B = o; j.KB = e[1];
                            Junctions.Add(j);
                        }
                    }
            }
        }
        Log.AppendLine("incroci trovati: " + Junctions.Count);
    }

    static double[] Smoothed(Road r)
    {
        int n = r.P.Count;
        double[] z = new double[n];
        for (int k = 0; k < n; k++) z[k] = Math.Max(Sample(r.P[k][0], r.P[k][1]), 1.4);
        for (int it = 0; it < 3; it++)
        {
            double[] t = new double[n];
            int win = 15;
            for (int k = 0; k < n; k++)
            {
                double s = 0; int c = 0;
                for (int q = -win; q <= win; q++)
                {
                    int kk = k + q;
                    if (r.Closed) kk = ((kk % (n - 1)) + (n - 1)) % (n - 1);
                    else if (kk < 0 || kk >= n) continue;
                    s += z[kk]; c++;
                }
                t[k] = s / c;
            }
            z = t;
        }
        return z;
    }

    // profilo: liscio, pendenza massima; agli incroci comanda la strada piu' importante,
    // quella secondaria si raccorda (piazzola piana di +-8 m)
    public static int Conflicts = 0; public static Dictionary<string, int> ConfKinds = new Dictionary<string, int>();
    static int Rank(Road r)
    {
        switch (r.Kind) { case "piazzola": case "statale": return 0; case "montagna": return 1; case "secondaria": return 2; case "citta": return 3; case "villaggio": return 4; default: return 5; }
    }
    static void ProfileAll()
    {
        Conflicts = 0; ConfKinds.Clear();
        var order = new List<Road>(Roads);
        order.Sort((a, b) => { int c = Rank(a).CompareTo(Rank(b)); return c != 0 ? c : b.P.Count.CompareTo(a.P.Count); });
        var done = new HashSet<Road>();
        foreach (var r in order)
        {
            double[] z = Smoothed(r); int n = z.Length; double step = 2.0;
            var fx = new Dictionary<int, double>();
            var src = new Dictionary<int, Road>();
            foreach (var j in Junctions)
            {
                Road other = null; int kMe = -1, kO = -1;
                if (j.A == r) { other = j.B; kMe = j.KA; kO = j.KB; } else if (j.B == r) { other = j.A; kMe = j.KB; kO = j.KA; }
                if (other == null || !done.Contains(other)) continue;
                double zj = other.P[kO][2];
                bool clash = false;
                foreach (var kv in fx)
                {
                    if (src[kv.Key] == other && Math.Abs(kv.Key - kMe) < 40) continue;   // stesso incrocio rilevato due volte
                    if (Math.Abs(kv.Value - zj) > r.MaxGrade * 1.15 * Math.Max(2.0, Math.Abs(kv.Key - kMe) * 2.0 - 16)) { clash = true; break; }
                }
                if (clash) { Conflicts++; string kk = r.Kind + "/" + other.Kind; if (!ConfKinds.ContainsKey(kk)) ConfKinds[kk] = 0; ConfKinds[kk]++; continue; }
                for (int q = -4; q <= 4; q++) { int k = kMe + q; if (k >= 0 && k < n && !(fx.ContainsKey(k) && src[k] != other)) { fx[k] = zj; src[k] = other; } }
            }
            for (int it = 0; it < 6; it++)
            {
                foreach (var kv in fx) z[kv.Key] = kv.Value;
                for (int k = 1; k < n; k++) if (!fx.ContainsKey(k)) z[k] = Math.Min(Math.Max(z[k], z[k - 1] - r.MaxGrade * step), z[k - 1] + r.MaxGrade * step);
                for (int k = n - 2; k >= 0; k--) if (!fx.ContainsKey(k)) z[k] = Math.Min(Math.Max(z[k], z[k + 1] - r.MaxGrade * step), z[k + 1] + r.MaxGrade * step);
            }
            for (int k = 0; k < n; k++) r.P[k][2] = Math.Max(z[k], 1.4);
            done.Add(r);
        }
    }
    // incide le strade nel terreno: piano di traverso sulla carreggiata + banchina, scarpate raccordate
    public static void ApplyRoads(int passes)
    {
        RoadMask = new byte[N * N];
        for (int pass = 0; pass < passes; pass++)
        {
            if (pass == 0) FindJunctions();
            ProfileAll();
            float[] best = new float[N * N];      // peso migliore per cella
            float[] tgt = new float[N * N];
            float[] sink = new float[N * N];      // quanto il terreno resta sotto la strada (solo sotto la carreggiata)
            for (int k = 0; k < best.Length; k++) best[k] = 0;
            foreach (var r in Roads)
            {
                // v0.32: banchina piana di 2,5 m (era 1,5): il terreno a 4 m di maglia non sale sopra il bordo della strada
                double half = r.Width * 0.5 + 2.5;   // carreggiata + banchina piana
                double edge = r.Width * 0.5;
                for (int k = 0; k + 1 < r.P.Count; k++)
                {
                    double ax = r.P[k][0], ay = r.P[k][1], az = r.P[k][2];
                    double bx = r.P[k + 1][0], by = r.P[k + 1][1], bz = r.P[k + 1][2];
                    double diff = Math.Abs(Sample((ax + bx) / 2, (ay + by) / 2) - (az + bz) / 2);
                    double blend = Math.Max(6, Math.Min(60, diff * 2.6 + 6));   // scarpata ~1:2.6
                    double outer = half + blend;
                    int i0 = (int)Math.Floor((Math.Min(ax, bx) - outer + HALF) / CELL), i1 = (int)Math.Ceiling((Math.Max(ax, bx) + outer + HALF) / CELL);
                    int j0 = (int)Math.Floor((Math.Min(ay, by) - outer + HALF) / CELL), j1 = (int)Math.Ceiling((Math.Max(ay, by) + outer + HALF) / CELL);
                    double dx = bx - ax, dy = by - ay, L2 = dx * dx + dy * dy;
                    for (int j = Math.Max(0, j0); j <= Math.Min(N - 1, j1); j++)
                        for (int i = Math.Max(0, i0); i <= Math.Min(N - 1, i1); i++)
                        {
                            double px = X(i) - ax, py = X(j) - ay;
                            double t = L2 > 0 ? Math.Max(0, Math.Min(1, (px * dx + py * dy) / L2)) : 0;
                            double qx = px - t * dx, qy = py - t * dy;
                            double d = Math.Sqrt(qx * qx + qy * qy);
                            if (d > outer) continue;
                            double w = d <= half ? 1 : Smooth(outer, half, d);
                            int id = Idx(i, j);
                            if (w > best[id] + 1e-4 || (Math.Abs(w - best[id]) < 1e-4 && w >= 0.999))
                            {
                                double zt = az + (bz - az) * t;
                                // 20 cm sotto la carreggiata, a filo della strada dal bordo in fuori (v0.32: prima anche la banchina
                                // stava 20 cm sotto e la strada sembrava un foglio appoggiato)
                                double sk = 0.2 * Smooth(edge + 0.6, edge - 0.4, d);
                                if (w >= 0.999 && best[id] >= 0.999) { zt = Math.Min(zt, tgt[id]); sk = Math.Max(sk, sink[id]); }   // sovrapposizioni: il terreno resta sotto entrambe
                                best[id] = (float)w; tgt[id] = (float)zt; sink[id] = (float)sk;
                            }
                            if (pass == passes - 1)
                            {
                                byte m = (byte)Math.Min(255, 255 * Smooth(half + 6, half - 0.5, d));
                                if (m > RoadMask[id]) RoadMask[id] = m;
                            }
                        }
                }
            }
            // applica partendo sempre dal terreno originale (cosi' le passate non si accumulano)
            System.Threading.Tasks.Parallel.For(0, N * N, id =>
            {
                double w = best[id];
                H[id] = w > 0 ? (float)Lerp(H0[id], tgt[id] - sink[id], w) : H0[id];   // sotto la carreggiata il terreno resta 20 cm piu' basso: la strada non viene mai coperta
            });
        }
        // la quota finale della strada e' quella del terreno spianato
        // la mesh della strada usa il proprio profilo (liscio, pendenza limitata); il terreno sotto e' allineato o appena piu' basso
        Log.AppendLine("strade incise nel terreno");
    }

    // ---------------- vegetazione: posizioni (ordine casuale, cosi' i primi N sono distribuiti su tutta l'isola) ----
    // v0.32 (Stefano 22/11/2026: "zone, boschi, radure, piu' modelli"): non piu' tutto sparso a caso ma per zone.
    // Spiaggia con palme da cocco a gruppi; pianura costiera con boschi, radure d'erba e felci, macchie di cespugli;
    // il versante a nord-est (umido, prende il vento) piu' fitto di quello a sud-ovest; in alto pini fino al limite
    // degli alberi, poi rocce ed erba; rocce con il muschio dove e' umido; cespugli lungo i bordi delle strade e
    // palme lungo le vie della citta'. Ogni punto viene tenuto con la probabilita' della sua zona (densita').
    public static readonly string[] VegKinds = { "palma", "cocco", "albero", "pino", "erba", "felce", "cespuglio", "roccia", "roccia_muschio" };
    public static string Scatter(string path, int total, int seed)
    {
        var rnd = new Random(seed);
        var cats = new Dictionary<string, List<string>>();
        foreach (var k in VegKinds) cats[k] = new List<string>();
        var ci = System.Globalization.CultureInfo.InvariantCulture;
        int tries = 0, placed = 0;
        while (tries < total * 60 && placed < total)
        {
            tries++;
            double x = (rnd.NextDouble() * 2 - 1) * (HALF - 50), y = (rnd.NextDouble() * 2 - 1) * (HALF - 50);
            double h = Sample(x, y);
            if (h < 1.0) continue;
            double hx = Sample(x + 3, y) - Sample(x - 3, y), hy = Sample(x, y + 3) - Sample(x, y - 3);
            double slope = Math.Sqrt(hx * hx + hy * hy) / 6.0;
            int i = (int)Math.Round((x + HALF) / CELL), j = (int)Math.Round((y + HALF) / CELL);
            int road = RoadMask[Idx(i, j)];
            if (road > 40) continue;   // niente sulla strada e sulla banchina
            bool roadside = road > 0;  // fascia di ~6-9 m oltre il bordo della strada
            bool city = Dist(x, y, CityX, CityY) < CityR * 0.85;
            bool village = Dist(x, y, VilWX, VilWY) < VilR * 0.85 || Dist(x, y, VilEX, VilEY) < VilR * 0.85;
            // umidita': il lato a nord-est (x+, y-) prende il vento dal mare; piu' una macchia di rumore
            double ne = ((x - PeakX) - (y - PeakY)) / (Math.Sqrt(2) * 3500.0);
            double wet = Math.Max(0, Math.Min(1, 0.5 + 0.45 * ne + 0.6 * Fbm(x / 1100.0, y / 1100.0, 3, 501)));
            // boschi e radure: rumore a macchie di qualche centinaio di metri
            double wood = Fbm(x / 520.0, y / 520.0, 4, 502) + (wet - 0.5) * 0.5;
            double grove = Fbm(x / 140.0, y / 140.0, 2, 503);   // gruppi di palme sulla spiaggia
            double r = rnd.NextDouble();
            double dens; string cat = null;
            if (h < 2.2)
            {   // spiaggia: sabbia libera, palme da cocco a gruppi
                if (slope > 0.3) continue;
                dens = grove > 0.12 ? 0.5 : 0.04;
                cat = r < 0.85 ? "cocco" : "erba";
            }
            else if (city || village)
            {   // citta' e villaggi: palme lungo le vie, qualche cespuglio, prati
                dens = roadside ? 0.7 : 0.08;
                cat = roadside ? (r < 0.6 ? "palma" : "cespuglio") : (r < 0.5 ? "erba" : (r < 0.75 ? "cespuglio" : "albero"));
            }
            else if (slope > 0.65)
            {   // pareti ripide: rocce (col muschio dove e' umido)
                dens = 0.35;
                cat = r < wet * 0.7 ? "roccia_muschio" : "roccia";
            }
            else if (roadside && h < 420)
            {   // bordo strada: cespugli e qualche albero, l'erba alta
                dens = 0.55;
                cat = r < 0.5 ? "cespuglio" : (r < 0.8 ? "erba" : (h < 40 ? "palma" : "albero"));
            }
            else if (h < 40)
            {   // pianura costiera
                if (wood > 0.12)
                {   // boschetto di palme e latifoglie, felci sotto
                    dens = 0.75;
                    cat = r < 0.30 ? "palma" : (r < 0.40 ? "cocco" : (r < 0.62 ? "albero" : (r < 0.82 ? "felce" : "cespuglio")));
                }
                else if (wood < -0.12)
                {   // radura: prato aperto
                    dens = 0.22;
                    cat = r < 0.80 ? "erba" : (r < 0.92 ? "felce" : "roccia");
                }
                else
                {   // campagna: erba e cespugli con alberi sparsi
                    dens = 0.3;
                    cat = r < 0.45 ? "erba" : (r < 0.70 ? "cespuglio" : (r < 0.85 ? "palma" : (r < 0.95 ? "albero" : "roccia")));
                }
            }
            else if (h < 420)
            {   // versanti: foresta fitta dove e' umido, radure e rocce altrove
                double treeline = 1 - Smooth(330, 420, h);   // 1 sotto i 330 m, 0 a 420
                if (wood > 0.0 - wet * 0.15)
                {
                    dens = 0.85 * (0.6 + 0.4 * wet);
                    cat = r < 0.55 * treeline ? (h > 300 && r < 0.25 ? "pino" : "albero") : (r < 0.75 ? "felce" : (r < 0.88 ? "cespuglio" : (r < 0.96 ? "erba" : (wet > 0.5 ? "roccia_muschio" : "roccia"))));
                }
                else
                {
                    dens = 0.25;
                    cat = r < 0.6 ? "erba" : (r < 0.75 ? "cespuglio" : (r < 0.88 ? "roccia" : (r < 0.95 ? "albero" : "palma")));
                }
            }
            else if (h < 560)
            {   // in alto: pini radi a gruppi, erba e rocce
                dens = wood > -0.05 ? 0.5 : 0.2;
                cat = wood > -0.05 && r < 0.55 ? "pino" : (r < 0.75 ? "erba" : "roccia");
            }
            else
            {   // vicino al cratere: roccia nuda
                dens = 0.15;
                cat = r < 0.75 ? "roccia" : "erba";
            }
            if (cat == null || rnd.NextDouble() > dens) continue;
            double yaw = rnd.NextDouble() * 360, sc = 0.8 + rnd.NextDouble() * 0.45;
            if (cat == "albero" && wood > 0.3) sc *= 1.25;   // nel cuore del bosco gli alberi sono piu' grandi
            cats[cat].Add("[" + x.ToString("F1", ci) + "," + y.ToString("F1", ci) + "," + (h - 0.15).ToString("F2", ci) + "," + yaw.ToString("F0", ci) + "," + sc.ToString("F2", ci) + "]");
            placed++;
        }
        var sb = new StringBuilder("{");
        bool first = true;
        foreach (var kv in cats) { if (!first) sb.Append(","); first = false; sb.Append("\"" + kv.Key + "\":[" + string.Join(",", kv.Value) + "]"); }
        sb.Append("}");
        File.WriteAllText(path, sb.ToString());
        var summary = new StringBuilder();
        foreach (var kv in cats) summary.Append(kv.Key + "=" + kv.Value.Count + " ");
        return summary.ToString();
    }

    // ---------------- statistiche ----------------
    public static string Stats()
    {
        var sb = new StringBuilder();
        double total = 0;
        var byKind = new Dictionary<string, double>();
        double maxG = 0; string maxGn = "";
        foreach (var r in Roads)
        {
            double L = 0;
            for (int k = 1; k < r.P.Count; k++)
            {
                double l = Dist(r.P[k][0], r.P[k][1], r.P[k - 1][0], r.P[k - 1][1]);
                L += l;
            }
            // pendenza media su 20 m
            for (int k = 10; k < r.P.Count; k += 5)
            {
                double l = 0; for (int q = k - 9; q <= k; q++) l += Dist(r.P[q][0], r.P[q][1], r.P[q - 1][0], r.P[q - 1][1]);
                double g = Math.Abs(r.P[k][2] - r.P[k - 10][2]) / Math.Max(l, 1);
                if (g > maxG) { maxG = g; maxGn = r.Name + " @(" + r.P[k][0].ToString("F0") + "," + r.P[k][1].ToString("F0") + ") z " + r.P[k - 10][2].ToString("F1") + "->" + r.P[k][2].ToString("F1") + " k=" + k + "/" + r.P.Count; }
            }
            total += L;
            if (!byKind.ContainsKey(r.Kind)) byKind[r.Kind] = 0;
            byKind[r.Kind] += L;
        }
        sb.AppendLine("strade totali: " + Roads.Count + ", lunghezza " + (total / 1000).ToString("F1") + " km");
        foreach (var kv in byKind) sb.AppendLine("  " + kv.Key + ": " + (kv.Value / 1000).ToString("F1") + " km");
        int over = 0, tot = 0; var hot = new List<string>();
        foreach (var r in Roads)
            for (int k = 10; k < r.P.Count; k += 5)
            {
                double g = Math.Abs(r.P[k][2] - r.P[k - 10][2]) / 20.0; tot++;
                if (g > 0.13)
                {
                    over++;
                    if (hot.Count < 12)
                    {
                        string near = "";
                        foreach (var o in Roads) { if (o == r) continue; foreach (var q in o.P) if (Dist(q[0], q[1], r.P[k][0], r.P[k][1]) < 25) { near = o.Name; break; } if (near != "") break; }
                        hot.Add(r.Name + " (" + r.P[k][0].ToString("F0") + "," + r.P[k][1].ToString("F0") + ") " + (g * 100).ToString("F0") + "% vicino a: " + near);
                    }
                }
            }
        sb.AppendLine("tratti 20 m oltre 13%: " + over + " su " + tot + "; incroci non raccordabili (passano a quote diverse): " + Conflicts);
        foreach (var hs in hot) sb.AppendLine("   " + hs);
        foreach (var kv in ConfKinds) sb.AppendLine("   conflitti " + kv.Key + ": " + kv.Value);
        sb.AppendLine("pendenza max su 20 m: " + (maxG * 100).ToString("F1") + "% (" + maxGn + ")");
        float mn = float.MaxValue, mx = float.MinValue; int land = 0;
        for (int k = 0; k < H.Length; k++) { mn = Math.Min(mn, H[k]); mx = Math.Max(mx, H[k]); if (H[k] > 0) land++; }
        sb.AppendLine("altezze " + mn.ToString("F1") + " .. " + mx.ToString("F1") + " m, terra " + (land * CELL * CELL / 1e6).ToString("F1") + " km2");
        return sb.ToString();
    }

    // ---------------- anteprima PNG ----------------
    public static void Preview(string path, int size, bool roads)
    {
        var bmp = new Bitmap(size, size, PixelFormat.Format24bppRgb);
        double sc = (N - 1) / (double)(size - 1);
        for (int py = 0; py < size; py++)
            for (int px = 0; px < size; px++)
            {
                double x = -HALF + px * sc * CELL, y = -HALF + py * sc * CELL;
                double h = Sample(x, y);
                double hx = Sample(x + 6, y) - Sample(x - 6, y), hy = Sample(x, y + 6) - Sample(x, y - 6);
                double shade = Math.Max(0.25, Math.Min(1.25, 0.85 - (hx * 0.6 + hy * 0.6) / 12.0));
                double slope = Math.Sqrt(hx * hx + hy * hy) / 12.0;
                double r, g, b;
                if (h <= 0) { double dpt = Math.Min(1, -h / 40); r = Lerp(0.25, 0.02, dpt); g = Lerp(0.75, 0.18, dpt); b = Lerp(0.75, 0.38, dpt); shade = 1; }
                else if (h < 2.5) { r = 0.86; g = 0.8; b = 0.6; }
                else if (slope > 0.6) { r = 0.3; g = 0.27; b = 0.25; }
                else { double t = Math.Min(1, h / 700); r = Lerp(0.22, 0.5, t); g = Lerp(0.45, 0.42, t); b = Lerp(0.15, 0.25, t); }
                bmp.SetPixel(px, py, Color.FromArgb(Clamp(r * shade), Clamp(g * shade), Clamp(b * shade)));
            }
        if (roads)
        {
            using (var gr = Graphics.FromImage(bmp))
            {
                gr.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
                foreach (var r in Roads)
                {
                    Color col = r.Kind == "statale" ? Color.FromArgb(255, 230, 40, 40) : r.Kind == "montagna" ? Color.FromArgb(255, 255, 140, 0) : r.Kind == "sterrata" ? Color.FromArgb(255, 150, 90, 40) : r.Kind == "citta" ? Color.FromArgb(255, 245, 245, 245) : r.Kind == "villaggio" ? Color.FromArgb(255, 230, 230, 120) : Color.FromArgb(255, 255, 220, 60);
                    float wpx = (float)Math.Max(1.0, r.Width / (sc * CELL) * 1.4);
                    using (var pen = new Pen(col, wpx))
                    {
                        var pts = new PointF[r.P.Count];
                        for (int k = 0; k < r.P.Count; k++) pts[k] = new PointF((float)((r.P[k][0] + HALF) / CELL / sc), (float)((r.P[k][1] + HALF) / CELL / sc));
                        if (pts.Length > 1) gr.DrawLines(pen, pts);
                    }
                }
            }
        }
        bmp.Save(path, ImageFormat.Png);
        bmp.Dispose();
    }
    static int Clamp(double v) { return (int)Math.Max(0, Math.Min(255, v * 255)); }

    // ---------------- esportazione ----------------
    public static void WriteR16(string path)
    {
        using (var bw = new BinaryWriter(File.Create(path)))
            for (int k = 0; k < H.Length; k++) bw.Write((ushort)Math.Max(0, Math.Min(65535, Math.Round((H[k] + 256.0) * 64.0))));  // h = v/64 - 256
    }

    // glb: posizioni in coordinate glTF = (X, Z, Y) dai metri Unreal (mappatura verificata con X5)
    public static void WriteGlb(string path, List<float> pos, List<float> nrm, List<float> uv, List<float> col, List<int[]> prims, List<string> mats)
    {
        var bin = new MemoryStream();
        var bw = new BinaryWriter(bin);
        int vcount = pos.Count / 3;
        float[] mn = { float.MaxValue, float.MaxValue, float.MaxValue }, mx = { float.MinValue, float.MinValue, float.MinValue };
        for (int i = 0; i < vcount; i++) for (int c = 0; c < 3; c++) { mn[c] = Math.Min(mn[c], pos[i * 3 + c]); mx[c] = Math.Max(mx[c], pos[i * 3 + c]); }
        var views = new List<string>(); var accs = new List<string>();
        Action<int, int, string, string, string> addView = (off, len, target, acc, dummy) => { };
        int offPos = (int)bin.Position; foreach (var f in pos) bw.Write(f);
        int offN = (int)bin.Position; foreach (var f in nrm) bw.Write(f);
        int offUV = (int)bin.Position; foreach (var f in uv) bw.Write(f);
        int offC = (int)bin.Position; if (col != null) foreach (var f in col) bw.Write(f);
        views.Add("{\"buffer\":0,\"byteOffset\":" + offPos + ",\"byteLength\":" + (pos.Count * 4) + ",\"target\":34962}");
        views.Add("{\"buffer\":0,\"byteOffset\":" + offN + ",\"byteLength\":" + (nrm.Count * 4) + ",\"target\":34962}");
        views.Add("{\"buffer\":0,\"byteOffset\":" + offUV + ",\"byteLength\":" + (uv.Count * 4) + ",\"target\":34962}");
        accs.Add("{\"bufferView\":0,\"componentType\":5126,\"count\":" + vcount + ",\"type\":\"VEC3\",\"min\":[" + F(mn[0]) + "," + F(mn[1]) + "," + F(mn[2]) + "],\"max\":[" + F(mx[0]) + "," + F(mx[1]) + "," + F(mx[2]) + "]}");
        accs.Add("{\"bufferView\":1,\"componentType\":5126,\"count\":" + vcount + ",\"type\":\"VEC3\"}");
        accs.Add("{\"bufferView\":2,\"componentType\":5126,\"count\":" + vcount + ",\"type\":\"VEC2\"}");
        int colAcc = -1;
        if (col != null)
        {
            views.Add("{\"buffer\":0,\"byteOffset\":" + offC + ",\"byteLength\":" + (col.Count * 4) + ",\"target\":34962}");
            accs.Add("{\"bufferView\":3,\"componentType\":5126,\"count\":" + vcount + ",\"type\":\"VEC4\"}");
            colAcc = 3;
        }
        var primJson = new List<string>();
        for (int p = 0; p < prims.Count; p++)
        {
            while (bin.Position % 4 != 0) bw.Write((byte)0);
            int off = (int)bin.Position;
            foreach (int ix in prims[p]) bw.Write((uint)ix);
            views.Add("{\"buffer\":0,\"byteOffset\":" + off + ",\"byteLength\":" + (prims[p].Length * 4) + ",\"target\":34963}");
            accs.Add("{\"bufferView\":" + (views.Count - 1) + ",\"componentType\":5125,\"count\":" + prims[p].Length + ",\"type\":\"SCALAR\"}");
            primJson.Add("{\"attributes\":{\"POSITION\":0,\"NORMAL\":1,\"TEXCOORD_0\":2" + (colAcc >= 0 ? ",\"COLOR_0\":3" : "") + "},\"indices\":" + (accs.Count - 1) + ",\"material\":" + p + "}");
        }
        while (bin.Position % 4 != 0) bw.Write((byte)0);
        var matJson = new List<string>();
        foreach (var m in mats) matJson.Add("{\"name\":\"" + m + "\",\"pbrMetallicRoughness\":{\"baseColorFactor\":[0.6,0.6,0.6,1],\"metallicFactor\":0,\"roughnessFactor\":0.9}}");
        string name = Path.GetFileNameWithoutExtension(path);
        string json = "{\"asset\":{\"version\":\"2.0\",\"generator\":\"IsolaGen\"},\"scene\":0,\"scenes\":[{\"nodes\":[0]}],\"nodes\":[{\"name\":\"" + name + "\",\"mesh\":0}],"
            + "\"meshes\":[{\"name\":\"" + name + "\",\"primitives\":[" + string.Join(",", primJson) + "]}],"
            + "\"materials\":[" + string.Join(",", matJson) + "],"
            + "\"buffers\":[{\"byteLength\":" + bin.Length + "}],\"bufferViews\":[" + string.Join(",", views) + "],\"accessors\":[" + string.Join(",", accs) + "]}";
        byte[] jb = Encoding.UTF8.GetBytes(json);
        int jpad = (4 - jb.Length % 4) % 4;
        byte[] bb = bin.ToArray();
        using (var o = new BinaryWriter(File.Create(path)))
        {
            o.Write(0x46546C67u); o.Write(2u); o.Write((uint)(12 + 8 + jb.Length + jpad + 8 + bb.Length));
            o.Write((uint)(jb.Length + jpad)); o.Write(0x4E4F534Au); o.Write(jb); for (int i = 0; i < jpad; i++) o.Write((byte)0x20);
            o.Write((uint)bb.Length); o.Write(0x004E4942u); o.Write(bb);
        }
    }
    static string F(float v) { return v.ToString("R", System.Globalization.CultureInfo.InvariantCulture); }

    static void AddV(List<float> pos, List<float> nrm, List<float> uv, double x, double y, double z, double nx, double ny, double nz, double u, double v)
    {
        pos.Add((float)x); pos.Add((float)z); pos.Add((float)y);
        nrm.Add((float)nx); nrm.Add((float)nz); nrm.Add((float)ny);
        uv.Add((float)u); uv.Add((float)v);
    }
    // triangolo con normale verso l'alto in glTF (y): controlla il verso
    static void Tri(List<int> idx, List<float> pos, int a, int b, int c)
    {
        double ax = pos[a * 3], ay = pos[a * 3 + 1], az = pos[a * 3 + 2];
        double bx = pos[b * 3] - ax, by = pos[b * 3 + 1] - ay, bz = pos[b * 3 + 2] - az;
        double cx = pos[c * 3] - ax, cy = pos[c * 3 + 1] - ay, cz = pos[c * 3 + 2] - az;
        double ny = bz * cx - bx * cz;
        if (ny >= 0) { idx.Add(a); idx.Add(b); idx.Add(c); } else { idx.Add(a); idx.Add(c); idx.Add(b); }
    }

    public static int ExportTerrain(string dir, double tile, int stepCells)
    {
        Directory.CreateDirectory(dir);
        int tiles = (int)Math.Round(HALF * 2 / tile);
        int per = (int)Math.Round(tile / CELL);
        int written = 0;
        for (int tj = 0; tj < tiles; tj++)
            for (int ti = 0; ti < tiles; ti++)
            {
                int i0 = ti * per, j0 = tj * per;
                float hmax = float.MinValue;
                for (int j = j0; j <= j0 + per; j += 4) for (int i = i0; i <= i0 + per; i += 4) hmax = Math.Max(hmax, H[Idx(i, j)]);
                int st = hmax < -15 ? stepCells * 8 : stepCells;   // oceano profondo: maglia grossa
                int nv = per / st + 1;
                var pos = new List<float>(); var nrm = new List<float>(); var uv = new List<float>(); var col = new List<float>();
                for (int b = 0; b < nv; b++)
                    for (int a = 0; a < nv; a++)
                    {
                        int i = i0 + a * st, j = j0 + b * st;
                        double x = X(i), y = X(j), z = H[Idx(i, j)];
                        int il = Math.Max(0, i - st), ir = Math.Min(N - 1, i + st), jd = Math.Max(0, j - st), ju = Math.Min(N - 1, j + st);
                        double dzx = (H[Idx(ir, j)] - H[Idx(il, j)]) / ((ir - il) * CELL), dzy = (H[Idx(i, ju)] - H[Idx(i, jd)]) / ((ju - jd) * CELL);
                        double nl = Math.Sqrt(dzx * dzx + dzy * dzy + 1);
                        AddV(pos, nrm, uv, x, y, z, -dzx / nl, -dzy / nl, 1 / nl, x / 8.0, y / 8.0);
                        col.Add(RoadMask[Idx(i, j)] / 255f); col.Add(0); col.Add(0); col.Add(1);
                    }
                var idx = new List<int>();
                for (int b = 0; b + 1 < nv; b++)
                    for (int a = 0; a + 1 < nv; a++)
                    {
                        int v0 = b * nv + a, v1 = v0 + 1, v2 = v0 + nv, v3 = v2 + 1;
                        Tri(idx, pos, v0, v2, v1); Tri(idx, pos, v1, v2, v3);
                    }
                WriteGlb(Path.Combine(dir, "terreno_" + ti + "_" + tj + ".glb"), pos, nrm, uv, col, new List<int[]> { idx.ToArray() }, new List<string> { "Terreno" });
                written++;
            }
        return written;
    }

    // mesh strada (v0.32, Stefano 22/11/2026): carreggiata spessa 6 cm sopra il profilo, con un bordo che scende
    // dolce nel terreno (niente scalino ad angolo retto); incroci puliti: dove due strade si sovrappongono resta
    // solo l'asfalto di quella piu' importante, senza strisce dentro l'incrocio, con la linea di stop sulla
    // secondaria; le linee di bordo della principale si aprono dove entra la secondaria.
    public const double ROAD_TOP = 0.06;      // spessore della strada sopra il profilo
    public const double SKIRT_RUN = 0.6;      // il bordo scende per 60 cm in orizzontale...
    public const double SKIRT_DROP = 0.12;    // ...fino a 6 cm sotto il profilo, poi un labbro nel terreno
    public const double SKIRT_LIP = 0.45;
    static Dictionary<long, List<int[]>> _roadMap;   // celle di 16 m: [strada, campione]
    static int Prio(int ri) { return Rank(Roads[ri]) * 1000 + ri; }   // piu' basso = piu' importante
    static void BuildRoadMap()
    {
        _roadMap = new Dictionary<long, List<int[]>>();
        for (int ri = 0; ri < Roads.Count; ri++)
            for (int k = 0; k < Roads[ri].P.Count; k++)
            {
                long key = ((long)Math.Floor((Roads[ri].P[k][0] + HALF) / 16) << 20) + (long)Math.Floor((Roads[ri].P[k][1] + HALF) / 16);
                List<int[]> l; if (!_roadMap.TryGetValue(key, out l)) { l = new List<int[]>(); _roadMap[key] = l; }
                l.Add(new int[] { ri, k });
            }
    }
    // distanza dal centro della strada ri (segmenti attorno ai campioni vicini), solo entro ~24 m
    static double DistTo(int ri, double x, double y)
    {
        long cx = (long)Math.Floor((x + HALF) / 16), cy = (long)Math.Floor((y + HALF) / 16);
        double best = 1e9; var P = Roads[ri].P;
        for (long dx = -1; dx <= 1; dx++) for (long dy = -1; dy <= 1; dy++)
            {
                List<int[]> l; if (!_roadMap.TryGetValue(((cx + dx) << 20) + cy + dy, out l)) continue;
                foreach (var e in l)
                {
                    if (e[0] != ri) continue;
                    int k = e[1];
                    for (int q = Math.Max(0, k - 1); q < Math.Min(P.Count - 1, k + 1); q++) best = Math.Min(best, SegDist(x, y, P[q], P[q + 1]));
                }
            }
        return best;
    }
    static double SegDist(double x, double y, double[] a, double[] b)
    {
        double dx = b[0] - a[0], dy = b[1] - a[1], L2 = dx * dx + dy * dy;
        double t = L2 > 0 ? Math.Max(0, Math.Min(1, ((x - a[0]) * dx + (y - a[1]) * dy) / L2)) : 0;
        return Dist(x, y, a[0] + t * dx, a[1] + t * dy);
    }
    // le altre strade che passano vicino al punto (entro 16-32 m)
    static HashSet<int> Around(double x, double y)
    {
        var o = new HashSet<int>();
        long cx = (long)Math.Floor((x + HALF) / 16), cy = (long)Math.Floor((y + HALF) / 16);
        for (long dx = -1; dx <= 1; dx++) for (long dy = -1; dy <= 1; dy++)
            {
                List<int[]> l; if (!_roadMap.TryGetValue(((cx + dx) << 20) + cy + dy, out l)) continue;
                foreach (var e in l) o.Add(e[0]);
            }
        return o;
    }
    // il punto (x, y) della strada ri sta sotto l'asfalto di una strada piu' importante?
    static bool Covered(int ri, double x, double y)
    {
        foreach (int o in Around(x, y))
            if (o != ri && Prio(o) < Prio(ri) && DistTo(o, x, y) < Roads[o].Width * 0.5 - 0.2) return true;
        return false;
    }
    // un'altra strada (qualsiasi) passa a meno di "margin" dal suo bordo?
    static bool NearOther(int ri, double x, double y, double margin)
    {
        foreach (int o in Around(x, y))
            if (o != ri && DistTo(o, x, y) < Roads[o].Width * 0.5 + margin) return true;
        return false;
    }
    public static int JunctionQuads = 0, StopLines = 0;

    public static int ExportRoads(string dir)
    {
        Directory.CreateDirectory(dir);
        BuildRoadMap();
        JunctionQuads = 0; StopLines = 0;
        int k = 0;
        var sb = new StringBuilder("[");
        for (int ri = 0; ri < Roads.Count; ri++)
        {
            var r = Roads[ri];
            var pos = new List<float>(); var nrm = new List<float>(); var uv = new List<float>();
            var road = new List<int>(); var lines = new List<int>();
            // le strade meno importanti stanno qualche millimetro piu' su: dove si sovrappongono non sfarfallano
            double eps = ROAD_TOP + 0.003 * Rank(r);
            double half = r.Width * 0.5;
            bool painted = r.Kind != "sterrata" && r.Kind != "piazzola";
            bool centre = r.Kind == "statale" || r.Kind == "montagna" || r.Kind == "secondaria";
            double dist = 0;
            int n = r.P.Count;
            int prevBase = -1;
            // sezione: labbro, bordo inclinato, linea, asfalto, mezzeria, asfalto, linea, bordo inclinato, labbro
            double[] offs = { -half - SKIRT_RUN - 0.1, -half - SKIRT_RUN, -half, -half + 0.3, -0.08, 0.08, half - 0.3, half, half + SKIRT_RUN, half + SKIRT_RUN + 0.1 };
            double[] zs = { -SKIRT_LIP, -SKIRT_DROP, eps, eps, eps, eps, eps, eps, -SKIRT_DROP, -SKIRT_LIP };
            var cov = new bool[n];
            for (int i = 1; i < n; i++) cov[i] = Covered(ri, (r.P[i][0] + r.P[i - 1][0]) * 0.5, (r.P[i][1] + r.P[i - 1][1]) * 0.5);
            var tx = new double[n]; var ty = new double[n];
            for (int i = 0; i < n; i++)
            {
                int ia = Math.Max(0, i - 1), ib = Math.Min(n - 1, i + 1);
                double ux = r.P[ib][0] - r.P[ia][0], uy = r.P[ib][1] - r.P[ia][1];
                double tl = Math.Sqrt(ux * ux + uy * uy); if (tl < 1e-6) tl = 1;
                tx[i] = ux / tl; ty[i] = uy / tl;
            }
            for (int i = 0; i < n; i++)
            {
                double nx = -ty[i], ny = tx[i];
                if (i > 0) dist += Dist(r.P[i][0], r.P[i][1], r.P[i - 1][0], r.P[i - 1][1]);
                int baseV = pos.Count / 3;
                for (int o = 0; o < offs.Length; o++)
                {
                    double x = r.P[i][0] + nx * offs[o], y = r.P[i][1] + ny * offs[o];
                    // normale del bordo inclinato: verso l'esterno e in su
                    double sn = (o == 1 || o == 0) ? -1 : (o >= 8 ? 1 : 0);
                    double ex = sn * nx * 0.3, ey = sn * ny * 0.3, el = Math.Sqrt(ex * ex + ey * ey + 1);
                    AddV(pos, nrm, uv, x, y, r.P[i][2] + zs[o], ex / el, ey / el, 1 / el, (offs[o] + half) / 4.0, dist / 4.0);
                }
                if (prevBase >= 0 && !cov[i])
                {
                    double mx = (r.P[i][0] + r.P[i - 1][0]) * 0.5, my = (r.P[i][1] + r.P[i - 1][1]) * 0.5;
                    double qx = -(ty[i] + ty[i - 1]) * 0.5, qy = (tx[i] + tx[i - 1]) * 0.5;
                    for (int st = 0; st < offs.Length - 1; st++)
                    {
                        int a = prevBase + st, b = prevBase + st + 1, c = baseV + st, d = baseV + st + 1;
                        double so = (offs[st] + offs[st + 1]) * 0.5;
                        double px = mx + qx * so, py = my + qy * so;
                        bool skirt = st <= 1 || st >= 7;
                        bool edgeLine = painted && (st == 2 || st == 6);
                        bool centreLine = st == 4 && centre && ((int)(dist / 6.0)) % 2 == 0;
                        // dentro un incrocio o davanti a una strada che entra: niente strisce
                        if (edgeLine && NearOther(ri, px, py, 1.0)) edgeLine = false;
                        if (centreLine && NearOther(ri, px, py, 0.5)) centreLine = false;
                        // il bordo inclinato non si stende sopra un'altra strada
                        if (skirt && NearOther(ri, px, py, -0.3)) continue;
                        var lst = (edgeLine || centreLine) ? lines : road;
                        Tri(lst, pos, a, c, b); Tri(lst, pos, b, c, d);
                    }
                    // linea di stop: l'ultimo pezzo prima di entrare nell'asfalto di una strada piu' importante
                    bool entering = i + 1 < n && cov[i + 1];
                    bool leaving = i >= 2 && cov[i - 1];
                    if (painted && (entering || leaving))
                    {
                        double t0 = entering ? 0.55 : 0.05, t1 = t0 + 0.2;
                        var A = r.P[i - 1]; var B = r.P[i];
                        int sb0 = pos.Count / 3;
                        foreach (double t in new[] { t0, t1 })
                            foreach (double o in new[] { -half + 0.3, half - 0.3 })
                            {
                                double x = A[0] + (B[0] - A[0]) * t + qx * o, y = A[1] + (B[1] - A[1]) * t + qy * o;
                                AddV(pos, nrm, uv, x, y, A[2] + (B[2] - A[2]) * t + eps + 0.01, 0, 0, 1, 0, 0);
                            }
                        Tri(lines, pos, sb0, sb0 + 2, sb0 + 1); Tri(lines, pos, sb0 + 1, sb0 + 2, sb0 + 3);
                        StopLines++;
                    }
                }
                else if (prevBase >= 0) JunctionQuads++;
                prevBase = baseV;
            }
            string mat = r.Kind == "sterrata" ? "Sterrato" : r.Kind == "citta" ? "AsfaltoCitta" : "Asfalto";
            var prims = new List<int[]> { road.ToArray() }; var mats = new List<string> { mat };
            if (lines.Count > 0) { prims.Add(lines.ToArray()); mats.Add("Segnaletica"); }
            if (road.Count == 0) { prims.RemoveAt(0); mats.RemoveAt(0); }
            if (prims.Count > 0) WriteGlb(Path.Combine(dir, "strada_" + k.ToString("D3") + ".glb"), pos, nrm, uv, null, prims, mats);
            if (k > 0) sb.Append(",");
            sb.Append("{\"file\":\"strada_" + k.ToString("D3") + ".glb\",\"name\":\"" + r.Name + "\",\"kind\":\"" + r.Kind + "\",\"width\":" + r.Width.ToString(System.Globalization.CultureInfo.InvariantCulture) + ",\"points\":[");
            for (int i = 0; i < n; i += 5)
            {
                if (i > 0) sb.Append(",");
                sb.Append("[" + r.P[i][0].ToString("F1", System.Globalization.CultureInfo.InvariantCulture) + "," + r.P[i][1].ToString("F1", System.Globalization.CultureInfo.InvariantCulture) + "," + r.P[i][2].ToString("F2", System.Globalization.CultureInfo.InvariantCulture) + "]");
            }
            sb.Append("]}");
            k++;
        }
        Log.AppendLine("strade esportate: " + k + ", pezzi coperti da un incrocio " + JunctionQuads + ", linee di stop " + StopLines);
        sb.Append("]");
        File.WriteAllText(Path.Combine(dir, "..", "strade.json"), sb.ToString());
        return k;
    }
}



















