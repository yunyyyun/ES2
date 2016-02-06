//
//  Shader.vsh
//  ES2
//
//  Created by mengyun on 16/2/2.
//  Copyright © 2016年 mengyun. All rights reserved.
//

attribute vec4 position;
//attribute vec3 normal;

//varying lowp vec4 colorVarying;

attribute vec2 TexCoordIn; // New
varying vec2 TexCoordOut; // New

uniform mat4 modelViewProjectionMatrix;
//uniform mat3 normalMatrix;

void main()
{
    //vec3 eyeNormal = normalize(normalMatrix * normal);
    //vec3 lightPosition = vec3(0.0, 0.0, 1.0);
    //vec4 diffuseColor = vec4(1, 1, 1, 1.0);
    
    //float nDotVP = max(0.0, dot(eyeNormal, normalize(lightPosition)));
                 
    //colorVarying = diffuseColor * nDotVP;
    
    gl_Position = modelViewProjectionMatrix * position;
    
    TexCoordOut = TexCoordIn;
}
