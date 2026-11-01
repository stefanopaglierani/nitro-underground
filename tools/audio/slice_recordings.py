#!/usr/bin/env python3
"""Cuts the recorded CC0 sounds in assets/audio/ out of the original downloads (see
assets/LICENSES.md for sources). Run it from a folder holding wav/<freesound id>.wav (the
Freesound previews converted to mono WAV) and wav/Car_Parking_Brake.wav; it writes oneshots/.
Needs numpy and scipy.
"""
import numpy as np, sys
from scipy.io import wavfile
from scipy import signal
SR=32000
def load(p):
    sr,x=wavfile.read(p); x=x.astype(float)/32768
    return signal.resample_poly(x, SR, sr) if sr!=SR else x
def cut(x,a,b): return x[int(a*SR):int(b*SR)]
def fade(x,fi=0.003,fo=0.05):
    x=x.copy(); a=int(fi*SR); b=int(fo*SR)
    if a: x[:a]*=np.linspace(0,1,a)
    if b: x[-b:]*=np.linspace(1,0,b)
    return x
def norm(x,p=0.9): return x*p/np.abs(x).max()
def save(p,x): wavfile.write(p,SR,(np.clip(x,-1,1)*32767).astype(np.int16))
def loop(x, xf):
    n=int(xf*SR); L=len(x)-n
    out=x[:L].copy(); w=np.linspace(0,1,n)
    out[:n]=x[:n]*np.sqrt(w)+x[L:L+n]*np.sqrt(1-w)
    return out
o='oneshots/'
import os; os.makedirs(o,exist_ok=True)
w='wav/'
hp=lambda x,f: signal.sosfilt(signal.butter(2,f,'high',fs=SR,output='sos'),x)
lp=lambda x,f: signal.sosfilt(signal.butter(2,f,'low',fs=SR,output='sos'),x)
save(o+'crash_heavy.wav', fade(norm(hp(cut(load(w+'237375.wav'),0.37,3.6),40),0.95),0.002,0.4))
save(o+'crash_medium.wav', fade(norm(hp(cut(load(w+'329516.wav'),0.13,2.0),40),0.95),0.002,0.4))
save(o+'crash_metal.wav', fade(norm(cut(load(w+'321482.wav'),0.13,1.3),0.9),0.002,0.2))
save(o+'crash_light.wav', fade(norm(load(w+'332056.wav'),0.9),0.001,0.03))
save(o+'land_thud.wav', fade(norm(lp(cut(load(w+'329516.wav'),0.13,0.9),700),0.95),0.002,0.2))
g=load(w+'116598.wav')
save(o+'gear_1.wav', fade(norm(hp(cut(g,2.53,2.95),60),0.9),0.002,0.08))
save(o+'gear_2.wav', fade(norm(hp(cut(g,1.92,2.30),60),0.9),0.002,0.08))
save(o+'handbrake.wav', fade(norm(load(w+'Car_Parking_Brake.wav'),0.9),0.002,0.08))
t=load(w+'71738.wav')
sq=loop(cut(t,8.30,9.35),0.25)
save(o+'tyre_squeal.wav', norm(hp(sq,200),0.8))
