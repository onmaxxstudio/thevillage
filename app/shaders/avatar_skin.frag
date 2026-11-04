#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform vec3 uSkin;
uniform vec3 uOutfit;
uniform vec3 uIris;
uniform vec4 uFeatures; // face, eyes, mouth, nose
uniform float uBrows;
uniform float uPresentation;
uniform sampler2D uBase;

out vec4 fragColor;

float region(vec2 p, vec2 center, vec2 radius) {
  return 1.0 - smoothstep(0.12, 1.0, length((p - center) / radius));
}

void main() {
  vec2 p = FlutterFragCoord().xy / uSize;
  float eyeY = uPresentation == 1.0 ? 0.482 : 0.498;
  vec2 eye = vec2(p.x < 0.5 ? 0.421 : 0.579, eyeY);
  vec2 nose = vec2(0.5, eyeY + 0.103);
  vec2 mouth = vec2(0.5, eyeY + 0.169);
  vec2 brow = eye - vec2(0, 0.065);
  vec2 q = p;
  q.x += (p.x - 0.5) * uFeatures.x * region(p, vec2(0.5, 0.62), vec2(0.33, 0.27));
  q.y += (p.y - 0.61) * uFeatures.x * region(p, vec2(0.5, 0.62), vec2(0.27, 0.27)) * 0.5;
  q.y += (p.y - eye.y) * uFeatures.y * region(p, eye, vec2(0.081, 0.052));
  q.y += uFeatures.z * (0.5 - abs(p.x - 0.5) * 12.0) * region(p, mouth, vec2(0.104, 0.062));
  q.x += (p.x - nose.x) * uFeatures.w * region(p, nose, vec2(0.105, 0.067));
  q.y += (p.y - brow.y) * uBrows * region(p, brow, vec2(0.08, 0.04));
  vec4 texel = texture(uBase, q);
  vec3 rgb = texel.rgb / max(texel.a, 0.001);
  float warm = smoothstep(0.03, 0.16, rgb.r - rgb.b) *
      smoothstep(0.01, 0.10, rgb.r - rgb.g);
  float clothing = smoothstep(0.72, 0.82, p.y) * (1.0 - warm);
  rgb = clamp(rgb * mix(vec3(1), uSkin, warm), 0.0, 1.0);
  rgb = clamp(rgb + clothing * uOutfit, 0.0, 1.0);
  float iris = region(q, eye, vec2(0.025, 0.029)) * smoothstep(0.05, 0.19, rgb.r);
  rgb = clamp(rgb + iris * uIris, 0.0, 1.0);
  fragColor = vec4(rgb * texel.a, texel.a);
}
