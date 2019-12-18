Shader "Custome/Tex Simulate Water"
{
	Properties 
	{
		_WaterTex ("Normal Map (RGB), Foam (A)", 2D) = "white" {}
		_AlphaTex("AlphaTex", 2D) = "black" {}
		_shadowLight ("shadowLight",range(0,1)) = 0
		_Tiling ("Wave Scale", Range(0.01, 1)) = 0.25
		_WaveSpeed("Wave Speed", float) = 0.4
		_SpecularRatio ("Specular Ratio", Range(10,500)) = 200
		_outSideColor("outSideColor",Color) = (0,0,0,0)
		_outSideLight("outSideLight",Range(0,10))=1
		_inSideColor("inSideColor",Color) = (0,0,0,0)
		_inSideLight("intSideLight",Range(0,10))=1
		_Alpha("Alpha",Range(0,1)) = 1
		_LightColorSelf ("LightColorSelf",Color) = (1,1,1,1)
		_LightDir ("LightDir",vector) = (0,1,0,0)
		_specularLight("specularLight",range(0.1,2)) =1	
	}
	
	SubShader 
	{  
		Tags 
		{
			"Queue"="Transparent-200"
			"RenderType"="Transparent" 
			"IgnoreProjector" = "True"
			"LightMode" = "ForwardBase"
		}
		LOD 250
		Pass
		{
 
			 ZWrite Off
			 Blend SrcAlpha OneMinusSrcAlpha
			 CGPROGRAM
 
			 #pragma vertex Vert
			 #pragma fragment Frag
			 #include "UnityCG.cginc"
			
			 float _Tiling;
			 float _WaveSpeed;
			 float _SpecularRatio;
			 sampler2D _WaterTex;
			 sampler2D _AlphaTex;
			 float4 _LightColorSelf;
			 float4 _LightDir;
			 float4 _outSideColor;
			 float _outSideLight;
			 float4 _inSideColor;
			 float _inSideLight;
			 float _shadowLight;
			 float _specularLight;
			 float _Alpha;
			 float _Intensity;
 
			struct v2f
			{
			    float4 position  : POSITION;
			    float3 worldView  : TEXCOORD0;
			    float3 tilingAndOffset:TEXCOORD2;
			    float3x3 tangentTransform:TEXCOORD4;  
			    float2 alphaUV :TEXCOORD7;
			};
 
			
 
			v2f Vert(appdata_full v)
			{
			    v2f o;
			    float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
			    
			    o.worldView = -normalize(worldPos - _WorldSpaceCameraPos);
			    o.position = UnityObjectToClipPos(v.vertex);
			    
			    o.tilingAndOffset.z =frac( _Time.x * _WaveSpeed);
			    o.tilingAndOffset.xy = worldPos.xz*_Tiling;
			    o.alphaUV = v.texcoord;
			      
			    float3 normal =normalize( UnityObjectToWorldNormal(v.normal));  
                float3 tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                float3 bitangentDir = normalize(cross(normal, tangentDir) * v.tangent.w); 
    
			    o.tangentTransform = float3x3( tangentDir, bitangentDir, normal);  
			    return o;
			}
 
			float4 Frag(v2f i):COLOR
			{
			    //move Normal Map to wave the water
			    fixed3 BumpMap01 = UnpackNormal(tex2D(_WaterTex,i.tilingAndOffset.xy + i.tilingAndOffset.z ));
			    fixed3 BumpMap02 = UnpackNormal(tex2D(_WaterTex,i.tilingAndOffset.xy*1.1 - i.tilingAndOffset.z));    
			    fixed3 N1 = normalize(mul( BumpMap01.rgb, i.tangentTransform ));
			    fixed3 N2 = normalize(mul( BumpMap02.rgb, i.tangentTransform ));
			    fixed3 worldNormal = N1*0.5 +N2*0.5;
    
          //light direction
			    float LdotN = dot(worldNormal, _LightDir.xyz);
    
			    //high light
			    float dotSpecular = dot(worldNormal,  normalize( i.worldView+_LightDir.xyz));
			    fixed3 specularReflection = pow(saturate(dotSpecular), _SpecularRatio)*_specularLight;
			    fixed4 alphaTex = tex2D (_AlphaTex,i.alphaUV);
			    fixed4 col =_LightColorSelf*2 * saturate (LdotN) ;

			    //Use AlphaTex.r to decide which part is deep
			    col.rgb = col.rgb * alphaTex.r *_inSideColor * _inSideLight  +  col.rgb * (1-alphaTex.r) * _outSideColor *_outSideLight + specularReflection;
			    col.a = _Alpha * alphaTex.r;
    
			    //Use AlphaTex.g to draw shadow
			    alphaTex.g = saturate(alphaTex.g + _shadowLight);
			    col.rgb *= alphaTex.g;
			    return col;
			}
		    ENDCG	
	    }  
	}
	FallBack "Diffuse"
}
