defmodule Gibbering.Engine.ConditionBadge do
  @moduledoc false

  # Renders small SVG badge icons for active conditions on an entity token.
  #
  # Badge strip sits just below the 32×32 sprite box (at y=34).
  # Up to @max_visible badges are shown left-to-right; any excess
  # is collapsed into a "+N" overflow badge.
  #
  # movement_exhausted is a pseudo-condition (not a D&D condition). It is
  # derived at render time from action_economy.movement_remaining == 0 and
  # clears naturally when advance_turn resets movement_remaining.

  @max_visible 3

  @badge_y 34
  @badge_spacing 10

  @colors %{
    movement_exhausted: "#f97316",
    prone: "#d97706",
    grappled: "#ef4444",
    restrained: "#8b5cf6",
    poisoned: "#16a34a",
    stunned: "#0891b2",
    incapacitated: "#6b7280",
    blinded: "#374151",
    deafened: "#64748b",
    unconscious: "#7f1d1d",
    dead: "#111827"
  }
  @default_color "#9ca3af"

  @doc """
  Returns the list of condition atoms to render for `entity`, including the
  `movement_exhausted` pseudo-condition when `movement_remaining == 0`.
  """
  @spec effective_conditions(map()) :: [atom()]
  def effective_conditions(entity) do
    real = Map.get(entity, :conditions, [])
    movement_remaining = get_in(entity, [:action_economy, :movement_remaining])

    pseudo =
      if is_integer(movement_remaining) && movement_remaining == 0,
        do: [:movement_exhausted],
        else: []

    pseudo ++ real
  end

  @doc """
  Renders the full badge strip SVG string for `entity`.
  Returns `""` when there are no active conditions.
  """
  @spec render_badges(map()) :: String.t()
  def render_badges(entity) do
    conditions = effective_conditions(entity)

    if conditions == [] do
      ""
    else
      {visible, overflow} = Enum.split(conditions, @max_visible)

      badge_frags =
        visible
        |> Enum.with_index()
        |> Enum.map(fn {cond_id, i} ->
          bx = i * @badge_spacing
          render_badge(cond_id, bx, @badge_y)
        end)

      overflow_frag =
        if overflow != [] do
          bx = length(visible) * @badge_spacing
          render_overflow(length(overflow), bx, @badge_y)
        else
          ""
        end

      (badge_frags ++ [overflow_frag])
      |> Enum.reject(&(&1 == ""))
      |> Enum.join("\n")
    end
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp render_badge(cond_id, bx, by) do
    color = Map.get(@colors, cond_id, @default_color)
    cx = bx + 4
    cy = by + 4

    ~s(<circle cx="#{cx}" cy="#{cy}" r="4" fill="#{color}" data-condition="#{cond_id}"/>\n) <>
      badge_icon(cond_id, bx, by)
  end

  defp render_overflow(n, bx, by) do
    cx = bx + 4
    cy = by + 4

    ~s(<circle cx="#{cx}" cy="#{cy}" r="4" fill="#374151"/>\n) <>
      ~s(<text x="#{cx}" y="#{by + 7}" font-size="5" text-anchor="middle" fill="white">+#{n}</text>)
  end

  # movement_exhausted — horizontal bar (no movement left)
  defp badge_icon(:movement_exhausted, bx, by) do
    ~s(<rect x="#{bx + 1}" y="#{by + 3}" width="6" height="2" rx="1" fill="white"/>)
  end

  # prone — down-pointing chevron (entity knocked flat)
  defp badge_icon(:prone, bx, by) do
    ~s(<path d="M#{bx + 2},#{by + 2} L#{bx + 4},#{by + 6} L#{bx + 6},#{by + 2}" fill="none" stroke="white" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>)
  end

  # grappled — two interlocked small circles (grabbed)
  defp badge_icon(:grappled, bx, by) do
    ~s(<circle cx="#{bx + 3}" cy="#{by + 4}" r="2" fill="none" stroke="white" stroke-width="1.2"/>\n) <>
      ~s(<circle cx="#{bx + 5}" cy="#{by + 4}" r="2" fill="none" stroke="white" stroke-width="1.2"/>)
  end

  # all other conditions — first letter of condition name
  defp badge_icon(cond_id, bx, by) do
    label = cond_id |> Atom.to_string() |> String.upcase() |> String.first()

    ~s(<text x="#{bx + 4}" y="#{by + 7}" font-size="6" text-anchor="middle" fill="white" font-weight="bold">#{label}</text>)
  end
end
