#!/usr/bin/env python

from scipy import ndimage 
import numpy as np
import cv2.cv as cv
import cv2
import video

help_message = '''

Tuslar:
 1 - HSV flow visualization
 2 - glitch

'''
kernel_1=np.array([ [0.0833 , 0.1666 , 0.0833] , [0.1666 ,0.000 ,0.1666] , [0.0833 , 0.1666 , 0.0833] ] )
print kernel_1
def turevler(prev,curr):
    Dx = cv2.Sobel(prev,cv2.CV_32F,1,0,ksize=1)
    Dy = cv2.Sobel(prev,cv2.CV_32F,0,1,ksize=1)
    Dt = curr-prev
    return Dx,Dy,Dt
def HSOF(prev,curr,alpha,itr):
    h, w = curr.shape[:2]
    flow=np.zeros((h,w,2),np.float32)
    Dx,Dy,Dt =turevler(prev,curr)
    for i in range(itr):
        uAvg=ndimage.convolve(flow[:,:,0],kernel_1,mode='constant',cval=0.0)
        vAvg=ndimage.convolve(flow[:,:,1],kernel_1,mode='constant',cval=0.0)
        #uAvg=cv2.filter2D(flow[:,:,0],cv2.CV_32F,kernel_1)
        #vAvg=cv2.filter2D(flow[:,:,1],cv2.CV_32F,kernel_1)
        Y=alpha*alpha + np.multiply(Dx,Dx) + np.multiply(Dy,Dy)
        dyv=np.multiply(Dy,vAvg)
        dxu=np.multiply(Dx,uAvg)
        flow[:,:,0]= uAvg - ( Dx*(dxu+ dyv + Dt ) )/Y
        flow[:,:,1]= vAvg - ( Dy*(dxu + dyv + Dt ) )/Y
    return flow
def draw_flow(img, flow, step=16):
    h, w = img.shape[:2]
    y, x = np.mgrid[step/2:h:step, step/2:w:step].reshape(2,-1)
    fx, fy = flow[y,x].T
    lines = np.vstack([x, y, x+fx, y+fy]).T.reshape(-1, 2, 2)
    lines = np.int32(lines + 0.5)
    vis = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
    cv2.polylines(vis, lines, 0, (0, 255, 0))
    for (x1, y1), (x2, y2) in lines:
        cv2.circle(vis, (x1, y1), 1, (0, 255, 0), -1)
    return vis

def draw_hsv(flow):
    h, w = flow.shape[:2]
    fx, fy = flow[:,:,0], flow[:,:,1]
    ang = np.arctan2(fy, fx) + np.pi
    v = np.sqrt(fx*fx+fy*fy)
    hsv = np.zeros((h, w, 3), np.uint8)
    hsv[...,0] = ang*(180/np.pi/2)
    hsv[...,1] = 255
    hsv[...,2] = np.minimum(v*4, 255)
    bgr = cv2.cvtColor(hsv, cv2.COLOR_HSV2BGR)
    return bgr

def warp_flow(img, flow):
    h, w = flow.shape[:2]
    flow = -flow
    flow[:,:,0] += np.arange(w)
    flow[:,:,1] += np.arange(h)[:,np.newaxis]
    res = cv2.remap(img, flow, None, cv2.INTER_LINEAR)
    return res

if __name__ == '__main__':
    import sys
    print help_message
    try: fn = sys.argv[1]
    except: fn = 0

    cam = video.create_capture(fn)
    ret, prev = cam.read()
    prevgray = cv2.cvtColor(prev, cv2.COLOR_BGR2GRAY)
    show_hsv = False
    show_glitch = False
    cur_glitch = prev.copy()
    while True:
        ret, img = cam.read()
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        gray = cv2.GaussianBlur(gray,(9,9),2)
        flow = 5*HSOF(prevgray,gray,50,5) #
        prevgray = gray 
        
        cv2.imshow('flow', draw_flow(gray, flow))
        if show_hsv:
            cv2.imshow('flow HSV', draw_hsv(flow))
        if show_glitch:
            cur_glitch = warp_flow(cur_glitch, flow)
            cv2.imshow('glitch', cur_glitch)

        ch = 0xFF & cv2.waitKey(5)
        if ch == 27:
            break
        if ch == ord('1'):
            show_hsv = not show_hsv
            print 'HSV flow visualization is', ['off', 'on'][show_hsv]
        if ch == ord('2'):
            show_glitch = not show_glitch
            if show_glitch:
                cur_glitch = img.copy()
            print 'glitch is', ['off', 'on'][show_glitch]
            
    cv2.destroyAllWindows()
