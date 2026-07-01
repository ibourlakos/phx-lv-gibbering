defmodule GibberingTalesWeb.Components.CharacterSprite do
  use GibberingTalesWeb, :html

  @doc """
  Renders a self-contained SVG portrait for a character.

  Accepts `race` ("human" | "elf" | "gnome"), `class_name` ("fighter" | "wizard" | "rogue"),
  and an optional `size` in pixels (default 64).
  """
  def character_sprite(assigns) do
    sprite = "#{assigns[:race]}_#{assigns[:class_name]}"

    assigns =
      assigns
      |> Map.put_new(:size, 64)
      |> Map.put(:sprite, sprite)

    ~H"""
    <svg
      width={@size}
      height={@size}
      viewBox="0 0 64 64"
      xmlns="http://www.w3.org/2000/svg"
      data-sprite={@sprite}
    >
      <.sprite_body sprite={@sprite} />
    </svg>
    """
  end

  # ---------------------------------------------------------------------------
  # Sprite bodies — 64×64 coordinate space, feet at y≈60, shadow at bottom.
  # ---------------------------------------------------------------------------

  def sprite_body(%{sprite: "human_fighter"} = assigns) do
    ~H"""
    <g>
      <ellipse cx="32" cy="60" rx="18" ry="6" fill="rgba(0,0,0,0.4)" />
      <rect x="20" y="44" width="9" height="16" rx="2" fill="#3a5075" stroke="#111" stroke-width="2" />
      <rect x="35" y="44" width="9" height="16" rx="2" fill="#3a5075" stroke="#111" stroke-width="2" />
      <rect x="17" y="22" width="30" height="24" rx="3" fill="#4a6fa5" stroke="#111" stroke-width="2" />
      <line x1="32" y1="22" x2="32" y2="46" stroke="#3a5075" stroke-width="1.5" />
      <rect x="17" y="42" width="30" height="4" fill="#8b6020" stroke="#111" stroke-width="1" />
      <rect x="7" y="22" width="11" height="16" rx="3" fill="#3a5075" stroke="#111" stroke-width="2" />
      <rect x="8" y="23" width="9" height="14" rx="2" fill="#c5a028" stroke="#111" stroke-width="1" />
      <line x1="12" y1="26" x2="12" y2="36" stroke="#8b6020" stroke-width="1" />
      <line x1="9" y1="30" x2="16" y2="30" stroke="#8b6020" stroke-width="1" />
      <ellipse cx="51" cy="27" rx="6" ry="8" fill="#3a5075" stroke="#111" stroke-width="2" />
      <line x1="55" y1="15" x2="55" y2="52" stroke="#a0a8b0" stroke-width="3" stroke-linecap="round" />
      <rect x="51" y="30" width="8" height="3" rx="1" fill="#a0a8b0" stroke="#111" stroke-width="1" />
      <ellipse cx="32" cy="14" rx="11" ry="11" fill="#c9a87c" stroke="#111" stroke-width="2" />
      <path d="M21,15 Q32,2 43,15" fill="#4a6fa5" stroke="#111" stroke-width="2" />
      <ellipse cx="32" cy="5" rx="8" ry="4" fill="#3a5075" stroke="#111" stroke-width="1.5" />
      <circle cx="28" cy="14" r="1.5" fill="#111" />
      <circle cx="36" cy="14" r="1.5" fill="#111" />
    </g>
    """
  end

  def sprite_body(%{sprite: "human_wizard"} = assigns) do
    ~H"""
    <g>
      <ellipse cx="32" cy="60" rx="14" ry="5" fill="rgba(0,0,0,0.4)" />
      <path d="M26,22 L20,58 L44,58 L38,22 Z" fill="#6040a0" stroke="#111" stroke-width="2" />
      <line x1="32" y1="26" x2="30" y2="54" stroke="#7a55b8" stroke-width="1.5" />
      <rect
        x="26"
        y="19"
        width="12"
        height="6"
        rx="2"
        fill="#7b5ea7"
        stroke="#111"
        stroke-width="1.5"
      />
      <ellipse cx="32" cy="14" rx="10" ry="10" fill="#c9a87c" stroke="#111" stroke-width="2" />
      <path d="M22,14 Q24,8 32,7 Q40,8 42,14" fill="#6b3a1f" stroke="#111" stroke-width="1.5" />
      <circle cx="28" cy="14" r="1.5" fill="#111" />
      <circle cx="36" cy="14" r="1.5" fill="#111" />
      <ellipse cx="32" cy="8" rx="14" ry="3" fill="#3b2060" stroke="#111" stroke-width="1.5" />
      <polygon points="32,0 19,9 45,9" fill="#3b2060" stroke="#111" stroke-width="1.5" />
      <line x1="47" y1="10" x2="45" y2="58" stroke="#7a5820" stroke-width="3" stroke-linecap="round" />
      <circle cx="47" cy="8" r="5" fill="#c090e8" stroke="#111" stroke-width="1.5" />
    </g>
    """
  end

  def sprite_body(%{sprite: "human_rogue"} = assigns) do
    ~H"""
    <g>
      <ellipse cx="32" cy="60" rx="16" ry="5" fill="rgba(0,0,0,0.4)" />
      <rect
        x="21"
        y="44"
        width="8"
        height="15"
        rx="2"
        fill="#3d2a1a"
        stroke="#111"
        stroke-width="1.5"
      />
      <rect
        x="35"
        y="44"
        width="8"
        height="15"
        rx="2"
        fill="#3d2a1a"
        stroke="#111"
        stroke-width="1.5"
      />
      <rect x="19" y="22" width="26" height="24" rx="3" fill="#6b4c38" stroke="#111" stroke-width="2" />
      <line x1="32" y1="22" x2="32" y2="46" stroke="#4a3020" stroke-width="1" />
      <ellipse cx="14" cy="30" rx="5" ry="8" fill="#5a3d28" stroke="#111" stroke-width="1.5" />
      <ellipse cx="50" cy="30" rx="5" ry="8" fill="#5a3d28" stroke="#111" stroke-width="1.5" />
      <line
        x1="10"
        y1="20"
        x2="12"
        y2="44"
        stroke="#b0b8c0"
        stroke-width="2.5"
        stroke-linecap="round"
      />
      <rect x="8" y="28" width="6" height="2" rx="1" fill="#888" stroke="#111" stroke-width="1" />
      <line
        x1="53"
        y1="20"
        x2="51"
        y2="44"
        stroke="#b0b8c0"
        stroke-width="2.5"
        stroke-linecap="round"
      />
      <rect x="49" y="28" width="6" height="2" rx="1" fill="#888" stroke="#111" stroke-width="1" />
      <ellipse cx="32" cy="14" rx="10" ry="10" fill="#c9a87c" stroke="#111" stroke-width="2" />
      <path
        d="M22,14 Q22,4 32,3 Q42,4 42,14 L42,18 Q36,16 32,16 Q28,16 22,18 Z"
        fill="#3d2a1a"
        stroke="#111"
        stroke-width="1.5"
      />
      <circle cx="28" cy="15" r="1.5" fill="#111" />
      <circle cx="36" cy="15" r="1.5" fill="#111" />
    </g>
    """
  end

  def sprite_body(%{sprite: "elf_fighter"} = assigns) do
    ~H"""
    <g>
      <ellipse cx="32" cy="60" rx="16" ry="5" fill="rgba(0,0,0,0.4)" />
      <rect x="22" y="44" width="8" height="16" rx="2" fill="#3a6050" stroke="#111" stroke-width="2" />
      <rect x="34" y="44" width="8" height="16" rx="2" fill="#3a6050" stroke="#111" stroke-width="2" />
      <rect x="19" y="22" width="26" height="24" rx="4" fill="#5a8f6a" stroke="#111" stroke-width="2" />
      <path d="M32,22 L32,46" stroke="#3a6050" stroke-width="1.5" />
      <rect x="19" y="42" width="26" height="4" fill="#4a7860" stroke="#111" stroke-width="1" />
      <ellipse cx="12" cy="30" rx="7" ry="9" fill="#3a6050" stroke="#111" stroke-width="2" />
      <path d="M8,25 Q12,22 16,25 L16,35 Q12,38 8,35 Z" fill="#5a8f6a" stroke="none" />
      <ellipse cx="51" cy="27" rx="5" ry="8" fill="#3a6050" stroke="#111" stroke-width="1.5" />
      <line x1="54" y1="4" x2="52" y2="58" stroke="#a0a8b0" stroke-width="2.5" stroke-linecap="round" />
      <polygon points="54,4 51,12 57,12" fill="#d0d8e0" stroke="#111" stroke-width="1" />
      <ellipse cx="32" cy="13" rx="9" ry="12" fill="#dbbf8a" stroke="#111" stroke-width="2" />
      <polygon points="23,10 20,4 25,10" fill="#dbbf8a" stroke="#111" stroke-width="1.5" />
      <polygon points="41,10 44,4 39,10" fill="#dbbf8a" stroke="#111" stroke-width="1.5" />
      <path d="M23,12 Q32,2 41,12" fill="#c0c8d0" stroke="#111" stroke-width="1.5" />
      <circle cx="28" cy="13" r="1.5" fill="#111" />
      <circle cx="36" cy="13" r="1.5" fill="#111" />
    </g>
    """
  end

  def sprite_body(%{sprite: "elf_wizard"} = assigns) do
    ~H"""
    <g>
      <ellipse cx="32" cy="60" rx="14" ry="5" fill="rgba(0,0,0,0.4)" />
      <path d="M24,22 L16,58 L48,58 L40,22 Z" fill="#5030a0" stroke="#111" stroke-width="2" />
      <path d="M24,22 L20,58" stroke="#7050c0" stroke-width="1" />
      <path d="M40,22 L44,58" stroke="#7050c0" stroke-width="1" />
      <line x1="32" y1="26" x2="32" y2="58" stroke="#7a55b8" stroke-width="1.5" />
      <rect
        x="26"
        y="19"
        width="12"
        height="6"
        rx="2"
        fill="#8060c0"
        stroke="#111"
        stroke-width="1.5"
      />
      <ellipse cx="32" cy="13" rx="9" ry="12" fill="#dbbf8a" stroke="#111" stroke-width="2" />
      <polygon points="23,10 20,4 25,10" fill="#dbbf8a" stroke="#111" stroke-width="1.5" />
      <polygon points="41,10 44,4 39,10" fill="#dbbf8a" stroke="#111" stroke-width="1.5" />
      <path d="M23,12 Q32,0 41,12" fill="#c8d0e0" stroke="#111" stroke-width="1.5" />
      <path d="M41,12 Q46,18 44,26" stroke="#c8d0e0" stroke-width="2" fill="none" />
      <circle cx="28" cy="13" r="1.5" fill="#111" />
      <circle cx="36" cy="13" r="1.5" fill="#111" />
      <line x1="48" y1="8" x2="46" y2="58" stroke="#8a6828" stroke-width="2.5" stroke-linecap="round" />
      <ellipse cx="48" cy="6" rx="6" ry="7" fill="#60e0ff" stroke="#111" stroke-width="1.5" />
      <ellipse cx="48" cy="6" rx="3" ry="4" fill="#a0f0ff" stroke="none" />
    </g>
    """
  end

  def sprite_body(%{sprite: "elf_rogue"} = assigns) do
    ~H"""
    <g>
      <ellipse cx="32" cy="60" rx="14" ry="4" fill="rgba(0,0,0,0.4)" />
      <rect
        x="22"
        y="44"
        width="7"
        height="16"
        rx="2"
        fill="#2a3a30"
        stroke="#111"
        stroke-width="1.5"
      />
      <rect
        x="35"
        y="44"
        width="7"
        height="16"
        rx="2"
        fill="#2a3a30"
        stroke="#111"
        stroke-width="1.5"
      />
      <path d="M20,22 L14,58 L50,58 L44,22 Z" fill="#1e2e28" stroke="#111" stroke-width="2" />
      <path d="M20,22 L16,58" stroke="#2e4038" stroke-width="1" />
      <path d="M44,22 L48,58" stroke="#2e4038" stroke-width="1" />
      <ellipse cx="14" cy="30" rx="4" ry="7" fill="#2a3a30" stroke="#111" stroke-width="1.5" />
      <ellipse cx="50" cy="30" rx="4" ry="7" fill="#2a3a30" stroke="#111" stroke-width="1.5" />
      <path
        d="M10,44 Q8,32 12,20"
        stroke="#c8d8e0"
        stroke-width="2.5"
        fill="none"
        stroke-linecap="round"
      />
      <path
        d="M54,44 Q56,32 52,20"
        stroke="#c8d8e0"
        stroke-width="2.5"
        fill="none"
        stroke-linecap="round"
      />
      <ellipse cx="32" cy="13" rx="9" ry="12" fill="#dbbf8a" stroke="#111" stroke-width="2" />
      <polygon points="23,10 20,4 25,10" fill="#dbbf8a" stroke="#111" stroke-width="1.5" />
      <polygon points="41,10 44,4 39,10" fill="#dbbf8a" stroke="#111" stroke-width="1.5" />
      <path
        d="M23,10 Q23,2 32,1 Q41,2 41,10 L42,16 Q36,14 32,14 Q28,14 22,16 Z"
        fill="#1e2e28"
        stroke="#111"
        stroke-width="1.5"
      />
      <circle cx="28" cy="13" r="1.5" fill="#111" />
      <circle cx="36" cy="13" r="1.5" fill="#111" />
    </g>
    """
  end

  def sprite_body(%{sprite: "gnome_fighter"} = assigns) do
    ~H"""
    <g>
      <ellipse cx="32" cy="60" rx="15" ry="5" fill="rgba(0,0,0,0.4)" />
      <rect x="22" y="48" width="8" height="12" rx="2" fill="#5c3a1a" stroke="#111" stroke-width="2" />
      <rect x="34" y="48" width="8" height="12" rx="2" fill="#5c3a1a" stroke="#111" stroke-width="2" />
      <rect x="16" y="30" width="32" height="20" rx="4" fill="#8b4513" stroke="#111" stroke-width="2" />
      <line x1="32" y1="30" x2="32" y2="50" stroke="#5c2a08" stroke-width="1.5" />
      <ellipse cx="11" cy="38" rx="6" ry="9" fill="#6b3510" stroke="#111" stroke-width="2" />
      <ellipse cx="53" cy="38" rx="6" ry="9" fill="#6b3510" stroke="#111" stroke-width="2" />
      <line x1="56" y1="15" x2="54" y2="58" stroke="#7a5820" stroke-width="3" stroke-linecap="round" />
      <path d="M56,15 Q65,10 62,22 Q59,28 54,26 Z" fill="#b0b8c0" stroke="#111" stroke-width="1.5" />
      <path d="M56,15 Q60,8 64,18 Q61,24 56,22 Z" fill="#9090a0" stroke="none" />
      <ellipse cx="32" cy="26" rx="12" ry="12" fill="#d4956a" stroke="#111" stroke-width="2" />
      <circle cx="28" cy="26" r="1.5" fill="#111" />
      <circle cx="36" cy="26" r="1.5" fill="#111" />
      <path d="M22,22 L22,14 Q32,8 42,14 L42,22" fill="#8b4513" stroke="#111" stroke-width="2" />
      <rect
        x="20"
        y="13"
        width="24"
        height="6"
        rx="2"
        fill="#7a3a10"
        stroke="#111"
        stroke-width="1.5"
      />
      <circle cx="26" cy="28" r="2.5" fill="#e8706a" fill-opacity="0.5" />
      <circle cx="38" cy="28" r="2.5" fill="#e8706a" fill-opacity="0.5" />
    </g>
    """
  end

  def sprite_body(%{sprite: "gnome_wizard"} = assigns) do
    ~H"""
    <g>
      <ellipse cx="32" cy="60" rx="12" ry="4" fill="rgba(0,0,0,0.4)" />
      <path d="M24,38 L20,60 L44,60 L40,38 Z" fill="#7040c0" stroke="#111" stroke-width="2" />
      <line x1="32" y1="40" x2="32" y2="60" stroke="#8050d0" stroke-width="1.5" />
      <rect
        x="24"
        y="35"
        width="16"
        height="6"
        rx="2"
        fill="#9060d0"
        stroke="#111"
        stroke-width="1.5"
      />
      <ellipse cx="32" cy="26" rx="12" ry="12" fill="#d4956a" stroke="#111" stroke-width="2" />
      <circle cx="27" cy="26" r="3" fill="white" stroke="#111" stroke-width="1.5" />
      <circle cx="37" cy="26" r="3" fill="white" stroke="#111" stroke-width="1.5" />
      <circle cx="27" cy="26" r="1.5" fill="#3060c0" />
      <circle cx="37" cy="26" r="1.5" fill="#3060c0" />
      <circle cx="24" cy="29" r="2.5" fill="#e8706a" fill-opacity="0.5" />
      <circle cx="40" cy="29" r="2.5" fill="#e8706a" fill-opacity="0.5" />
      <polygon points="32,2 20,20 44,20" fill="#4020a0" stroke="#111" stroke-width="2" />
      <ellipse cx="32" cy="20" rx="13" ry="4" fill="#5030b0" stroke="#111" stroke-width="1.5" />
      <circle cx="32" cy="2" r="3" fill="#f0d060" stroke="#111" stroke-width="1" />
      <line
        x1="48"
        y1="20"
        x2="46"
        y2="62"
        stroke="#6a4810"
        stroke-width="2.5"
        stroke-linecap="round"
      />
      <ellipse cx="48" cy="18" rx="5" ry="5" fill="#f0c060" stroke="#111" stroke-width="1.5" />
      <circle cx="48" cy="18" r="2" fill="white" />
    </g>
    """
  end

  def sprite_body(%{sprite: "gnome_rogue"} = assigns) do
    ~H"""
    <g>
      <ellipse cx="32" cy="60" rx="12" ry="4" fill="rgba(0,0,0,0.4)" />
      <rect
        x="23"
        y="48"
        width="7"
        height="12"
        rx="2"
        fill="#3a2a20"
        stroke="#111"
        stroke-width="1.5"
      />
      <rect
        x="34"
        y="48"
        width="7"
        height="12"
        rx="2"
        fill="#3a2a20"
        stroke="#111"
        stroke-width="1.5"
      />
      <rect x="19" y="30" width="26" height="20" rx="3" fill="#5d4037" stroke="#111" stroke-width="2" />
      <rect x="23" y="30" width="6" height="8" rx="1" fill="#4a3020" stroke="#111" stroke-width="1" />
      <rect x="35" y="30" width="6" height="8" rx="1" fill="#4a3020" stroke="#111" stroke-width="1" />
      <ellipse cx="14" cy="38" rx="5" ry="7" fill="#4a3020" stroke="#111" stroke-width="1.5" />
      <ellipse cx="50" cy="38" rx="5" ry="7" fill="#4a3020" stroke="#111" stroke-width="1.5" />
      <line x1="10" y1="44" x2="12" y2="30" stroke="#b8c0c8" stroke-width="2" stroke-linecap="round" />
      <line x1="54" y1="44" x2="52" y2="30" stroke="#b8c0c8" stroke-width="2" stroke-linecap="round" />
      <ellipse cx="32" cy="25" rx="11" ry="11" fill="#d4956a" stroke="#111" stroke-width="2" />
      <ellipse cx="27" cy="25" rx="4" ry="3.5" fill="#2a2a2a" stroke="#111" stroke-width="1.5" />
      <ellipse cx="37" cy="25" rx="4" ry="3.5" fill="#2a2a2a" stroke="#111" stroke-width="1.5" />
      <circle cx="27" cy="25" r="2" fill="#40c060" fill-opacity="0.7" />
      <circle cx="37" cy="25" r="2" fill="#40c060" fill-opacity="0.7" />
      <rect x="31" y="24" width="2" height="2" rx="1" fill="#2a2a2a" />
      <circle cx="24" cy="28" r="2" fill="#e8706a" fill-opacity="0.5" />
      <circle cx="40" cy="28" r="2" fill="#e8706a" fill-opacity="0.5" />
    </g>
    """
  end

  def sprite_body(assigns) do
    ~H"""
    <g>
      <rect x="8" y="8" width="48" height="48" rx="4" fill="#7f8c8d" stroke="#111" stroke-width="2" />
      <text x="32" y="36" text-anchor="middle" fill="#fff" font-size="10">?</text>
    </g>
    """
  end
end
