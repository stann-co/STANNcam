//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main()
{
    float res = 56.;
    
    vec4 color = vec4(1.);
    color.r = texture2D( gm_BaseTexture, v_vTexcoord + vec2(-1./res,0.)).r;
    color.gb = texture2D( gm_BaseTexture, v_vTexcoord ).gb;
    
    gl_FragColor = color;
}
