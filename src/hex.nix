{ oklch, srgb }:

let
  math = import ./utils/math.nix;

  tr = (import ./utils/transform.nix) { inherit math; };

  isHexWithHash =
    hex:
    (builtins.stringLength hex == 7 || builtins.stringLength hex == 9)
    && (builtins.substring 0 1 hex == "#");

  isHexCode =
    hex:
    (builtins.stringLength hex == 6 || builtins.stringLength hex == 8)
    && (builtins.substring 0 1 hex != "#");

  prefix =
    hex:
    if builtins.isString hex then
      if isHexWithHash hex then
        "#"
      else if isHexCode hex then
        ""
      else
        throw "Character ${hex} is not a valid hex value."
    else
      throw "Character ${hex} is not a string.";
in
rec {
  to = {
    oklch = hex: srgb.to.oklch (to.srgb hex);

    oklchs = hexes: map (hex: to.oklch hex) hexes;

    srgb =
      hex:
      if isHexCode hex then
        {
          r = (tr.hexToDecimal (builtins.substring 0 2 hex)) / 255.0;
          g = (tr.hexToDecimal (builtins.substring 2 2 hex)) / 255.0;
          b = (tr.hexToDecimal (builtins.substring 4 2 hex)) / 255.0;
          a =
            let
              a = builtins.substring 6 2 hex;
            in
            (if builtins.stringLength a == 2 then (tr.hexToDecimal a) else 255) / 255.0;
        }
      else if isHexWithHash hex then
        {
          r = (tr.hexToDecimal (builtins.substring 1 2 hex)) / 255.0;
          g = (tr.hexToDecimal (builtins.substring 3 2 hex)) / 255.0;
          b = (tr.hexToDecimal (builtins.substring 5 2 hex)) / 255.0;
          a =
            let
              a = builtins.substring 7 2 hex;
            in
            (if builtins.stringLength a == 2 then (tr.hexToDecimal a) else 255) / 255.0;
        }
      else
        throw "Cannot complete the conversion";

    srgbs = hexes: map (hex: to.srgb hex) hexes;
  };

  lighten = hex: value: (prefix hex) + (oklch.to.hex (oklch.lighten (to.oklch hex) value));

  darken = hex: value: (prefix hex) + (oklch.to.hex (oklch.darken (to.oklch hex) value));

  blend =
    hex: another: value:
    (prefix hex) + (oklch.to.hex (oklch.blend (to.oklch hex) (to.oklch another) value));

  gradient =
    hex: another: steps:
    map (value: (prefix hex) + value) (
      oklch.to.hexes (oklch.gradient (to.oklch hex) (to.oklch another) steps)
    );

  shades =
    hex: steps:
    map (value: (prefix hex) + value) (oklch.to.hexes (oklch.shades (to.oklch hex) steps));

  tints =
    hex: steps:
    map (value: (prefix hex) + value) (oklch.to.hexes (oklch.tints (to.oklch hex) steps));

  tones =
    hex: steps:
    map (value: (prefix hex) + value) (oklch.to.hexes (oklch.tones (to.oklch hex) steps));

  polygon =
    hex: count:
    map (value: (prefix hex) + value) (oklch.to.hexes (oklch.polygon (to.oklch hex) count));

  complementary = hex: (prefix hex) + (oklch.to.hex (oklch.complementary (to.oklch hex)));

  analogous =
    hex: map (value: (prefix hex) + value) (oklch.to.hexes (oklch.analogous (to.oklch hex)));

  splitComplementary =
    hex:
    map (value: (prefix hex) + value) (oklch.to.hexes (oklch.splitComplementary (to.oklch hex)));

  setAlpha = hex: value: let
    rgb = (to.srgb hex) // { a = value; };
  in (prefix hex) + (srgb.to.hex rgb);

  stripAlpha = hex: let
    rgb = (to.srgb hex) // { a = 1.0; };
  in (prefix hex) + (srgb.to.hex rgb);

  incAlpha = hex: value: let
    rgb = to.srgb hex;
    inc = rgb // {
      a = rgb.a + value;
    };
  in (prefix hex) + (srgb.to.hex inc);

  decAlpha = hex: value: let
    rgb = to.srgb hex;
    dec = rgb // {
      a = rgb.a - value;
    };
  in (prefix hex) + (srgb.to.hex dec);
}
