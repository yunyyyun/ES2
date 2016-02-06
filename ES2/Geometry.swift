//
//  Geometry.swift
//  ES2
//
//  Created by mengyun on 16/2/2.
//  Copyright © 2016年 mengyun. All rights reserved.
//
import Foundation
import OpenGLES

let uStepsNum=40
let vStepsNum=40
let PI=3.1416
let PI2=3.1416*2

var m_VertexTest=[Double]()
var num_ver:Int!

func sin(var x:Double)->Double{
    var sign=1   //符号
    let itemCnt=4//泰勒级数
    var result:Double=0
    var tx:Double
    var factorial=1.0
    if x<0{
        x=0-x
        sign = -1*sign
    }
    if x>PI2{
        x=x-PI2
    }
    if x>PI{
        x=x-PI
        sign = -1*sign
    }
    if x*2>PI{
        x=PI-x
    }
    tx=x
    for k in 0...itemCnt-1{
        if k%2==0{
            result+=(tx/factorial)
        }
        else{
            result-=(tx/factorial)
        }
        tx*=(x*x)
        factorial=factorial*(2*Double(k+1))*(2*Double(k+1)+1)
    }
    result=Double(sign)*result
    return result
}
func cos(x:Double)->Double{
    return sin(PI/2-x)
}

func pointX(u:Double,v:Double)->Double{
    return sin(PI*v)*cos(PI2*u)
}
func pointY(u:Double,v:Double)->Double{
    return sin(PI*v)*sin(PI2*u)
}
func pointZ(u:Double,v:Double)->Double{
    return cos(PI*v)
}

func BallVertexData(){
    let uStep = 1.0/Double(uStepsNum)
    let vStep = 1.0/Double(vStepsNum)
    var u:Double=0
    var v:Double=0
    //绘制下端三角形组
//    for(int i = 0;i<uStepsNum;i++)
//    {
//        glBegin(GL_LINE_LOOP);
//        Point a = getPoint(0,0);
//        glVertex3d(a.x,a.y,a.z);
    
//        Point b = getPoint(u,vstep);
//        glVertex3d(b.x,b.y,b.z);
//        Point c = getPoint(u+ustep,vstep);
//        glVertex3d(c.x,c.y,c.z);
//        u += ustep;
//        glEnd();
//    }
//    double x = sin(PI*v)*cos(PI2*u);
//    double y = sin(PI*v)*sin(PI2*u);
//    double z = cos(PI*v);
    for _ in 0...uStepsNum-1{
        m_VertexTest+=[pointX(0, v: 0)]
        m_VertexTest+=[pointY(0, v: 0)]
        m_VertexTest+=[pointZ(0, v: 0)]
        
        m_VertexTest+=[1]
        m_VertexTest+=[0]
        m_VertexTest+=[0]
        
        m_VertexTest+=[pointX(u, v: vStep)]
        m_VertexTest+=[pointY(u, v: vStep)]
        m_VertexTest+=[pointZ(u, v: vStep)]
        
        m_VertexTest+=[1]
        m_VertexTest+=[0]
        m_VertexTest+=[0]
        
        m_VertexTest+=[pointX(u+uStep, v: vStep)]
        m_VertexTest+=[pointY(u+uStep, v: vStep)]
        m_VertexTest+=[pointZ(u+uStep, v: vStep)]
        
        m_VertexTest+=[1]
        m_VertexTest+=[0]
        m_VertexTest+=[0]
        
        u += uStep
    }
    //绘制中间四边形组
//    u = 0, v = vstep;
//    for(int i=1;i<vStepNum-1;i++)
//    {
//        for(int j=0;j<uStepsNum;j++)
//        {
//            glBegin(GL_LINE_LOOP);
//            Point a = getPoint(u,v);
//            Point b = getPoint(u+ustep,v);
//            Point c = getPoint(u+ustep,v+vstep);
//            Point d = getPoint(u,v+vstep);
//            glVertex3d(a.x,a.y,a.z);
//            glVertex3d(b.x,b.y,b.z);
//            glVertex3d(c.x,c.y,c.z);
//            glVertex3d(d.x,d.y,d.z);
//            u += ustep;
//            glEnd();
//        }
//        v += vstep;
//    }
    u=0
    v=vStep
    for _ in 1...vStepsNum-2{
        for _ in 0...uStepsNum-1{
            m_VertexTest+=[pointX(u, v: v)]
            m_VertexTest+=[pointY(u, v: v)]
            m_VertexTest+=[pointZ(u, v: v)]
            
            m_VertexTest+=[1]
            m_VertexTest+=[0]
            m_VertexTest+=[0]
            
            m_VertexTest+=[pointX(u+uStep, v: v)]
            m_VertexTest+=[pointY(u+uStep, v: v)]
            m_VertexTest+=[pointZ(u+uStep, v: v)]
            
            m_VertexTest+=[1]
            m_VertexTest+=[0]
            m_VertexTest+=[0]
            
            m_VertexTest+=[pointX(u+uStep, v: v+vStep)]
            m_VertexTest+=[pointY(u+uStep, v: v+vStep)]
            m_VertexTest+=[pointZ(u+uStep, v: v+vStep)]
            
            m_VertexTest+=[1]
            m_VertexTest+=[0]
            m_VertexTest+=[0]
            
            m_VertexTest+=[pointX(u, v: v+vStep)]
            m_VertexTest+=[pointY(u, v: v+vStep)]
            m_VertexTest+=[pointZ(u, v: v+vStep)]
            
            m_VertexTest+=[1]
            m_VertexTest+=[0]
            m_VertexTest+=[0]
            
            u += uStep
        }
        v += vStep
    }
    
    //绘制下端三角形组
//    u = 0;
//    for(int i=0;i<uStepsNum;i++)
//    {
//        glBegin(GL_LINE_LOOP);
//        Point a = getPoint(0,1);
//        Point b = getPoint(u,1-vstep);
//        Point c = getPoint(u+ustep,1-vstep);
//        glVertex3d(a.x,a.y,a.z);
//        glVertex3d(b.x,b.y,b.z);
//        glVertex3d(c.x,c.y,c.z);
//        glEnd();
//    }
    u=0
    for _ in 0...uStepsNum-1{
        m_VertexTest+=[pointX(0, v: 1)]
        m_VertexTest+=[pointY(0, v: 1)]
        m_VertexTest+=[pointZ(0, v: 1)]
        
        m_VertexTest+=[1]
        m_VertexTest+=[0]
        m_VertexTest+=[0]
        
        m_VertexTest+=[pointX(u, v: 1-vStep)]
        m_VertexTest+=[pointY(u, v: 1-vStep)]
        m_VertexTest+=[pointZ(u, v: 1-vStep)]
        
        m_VertexTest+=[1]
        m_VertexTest+=[0]
        m_VertexTest+=[0]
        
        m_VertexTest+=[pointX(u+uStep, v: 1-vStep)]
        m_VertexTest+=[pointY(u+uStep, v: 1-vStep)]
        m_VertexTest+=[pointZ(u+uStep, v: 1-vStep)]
        
        m_VertexTest+=[1]
        m_VertexTest+=[0]
        m_VertexTest+=[0]
    }
    num_ver=m_VertexTest.count
    print("cxcxcxccccc",num_ver,sin(0-PI/2),sin(PI))
}







