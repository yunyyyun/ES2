//
//  Shader.fsh
//  ES2
//
//  Created by mengyun on 16/2/2.
//  Copyright © 2016年 mengyun. All rights reserved.
//
varying lowp vec2 TexCoordOut;
uniform sampler2D Texture; // New
//varying lowp vec4 colorVarying;

void main()
{
    //gl_FragColor = colorVarying;
    gl_FragColor=texture2D(Texture, TexCoordOut);
}
