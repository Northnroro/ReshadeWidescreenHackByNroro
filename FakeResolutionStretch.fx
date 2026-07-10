#include "ReShade.fxh"

uniform bool EnableFakeResolutionStretch <
    ui_type = "checkbox";
    ui_label = "Enable";
    ui_tooltip = "Stretch the valid logical source area across the full backbuffer before later effects run.";
> = true;

uniform float SourceWidthRatio <
    ui_type = "drag";
    ui_min = 0.100;
    ui_max = 1.000;
    ui_step = 0.001;
    ui_label = "Source Width Ratio";
    ui_tooltip = "For 1920 logical width inside a 3840 physical backbuffer, use 0.5.";
> = 0.5;

float4 FakeResolutionStretchPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    if (!EnableFakeResolutionStretch)
        return tex2D(ReShade::BackBuffer, texcoord);

    const float2 source_uv = float2(saturate(texcoord.x * SourceWidthRatio), texcoord.y);
    return tex2D(ReShade::BackBuffer, source_uv);
}

technique FakeResolutionStretch <
    ui_tooltip = "Place this before SuperDepth3D. It stretches the logical left-side source to the full physical backbuffer.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = FakeResolutionStretchPS;
    }
}
