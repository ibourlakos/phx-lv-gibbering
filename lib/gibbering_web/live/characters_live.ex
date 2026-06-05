defmodule GibberingWeb.CharactersLive do
  use GibberingWeb, :live_view

  alias Gibbering.{Characters, Data}
  alias Gibbering.Catalogue.Cache, as: Catalogue
  import GibberingWeb.Components.CharacterSprite

  @standard_array [15, 14, 13, 12, 10, 8]

  @class_skill_choices %{
    "fighter" =>
      {2,
       ~w(acrobatics animal_handling athletics history insight intimidation perception survival)},
    "wizard" => {2, ~w(arcana history insight investigation medicine religion)},
    "rogue" =>
      {4,
       ~w(acrobatics athletics deception insight intimidation investigation perception performance persuasion sleight_of_hand stealth)}
  }

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    {:ok,
     socket
     |> assign(:characters, Characters.list_for_user(user.id))
     |> assign(:modal, :closed)
     |> assign(:char_draft, %{})
     |> assign(:modal_errors, [])
     |> assign(:preview_bg_key, "")
     |> assign(:preview_appearance, %{})}
  end

  # ---------------------------------------------------------------------------
  # Modal navigation
  # ---------------------------------------------------------------------------

  @impl true
  def handle_event("new_character", _params, socket) do
    {:noreply,
     socket
     |> assign(:modal, :identity)
     |> assign(:char_draft, %{})
     |> assign(:modal_errors, [])
     |> assign(:preview_bg_key, "")
     |> assign(:preview_appearance, %{})}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, socket |> assign(:modal, :closed) |> assign(:char_draft, %{})}
  end

  def handle_event("back_step", _params, socket) do
    {:noreply, assign(socket, :modal, prev_step(socket.assigns.modal))}
  end

  # ---------------------------------------------------------------------------
  # Live preview events
  # ---------------------------------------------------------------------------

  def handle_event("preview_identity", %{"identity" => params}, socket) do
    {:noreply, assign(socket, :preview_bg_key, params["background"] || "")}
  end

  def handle_event("preview_appearance", %{"appearance" => params}, socket) do
    {:noreply, assign(socket, :preview_appearance, params)}
  end

  # ---------------------------------------------------------------------------
  # Step: Identity
  # ---------------------------------------------------------------------------

  def handle_event("step_identity", %{"identity" => params}, socket) do
    errors = validate_identity(params)

    if errors == [] do
      race = params["race"] || "human"
      class = params["class"] || "fighter"
      background_key = params["background"]

      bg =
        if background_key && background_key != "",
          do: Data.Backgrounds.get(background_key),
          else: nil

      cls = Catalogue.get_class(class)

      # Pre-compute proficiencies from class + background for next steps
      saving_throws = if cls, do: cls.saving_throws, else: []
      bg_skills = if bg, do: bg.skill_proficiencies, else: []
      bg_tools = if bg, do: bg.tool_proficiencies, else: []

      draft =
        Map.merge(socket.assigns.char_draft, %{
          "name" => params["name"],
          "race" => race,
          "class" => class,
          "level" => String.to_integer(params["level"] || "1"),
          "alignment" => params["alignment"] || "true_neutral",
          "background" => background_key,
          "saving_throw_proficiencies" => saving_throws,
          "bg_skill_proficiencies" => bg_skills,
          "bg_tool_proficiencies" => bg_tools
        })

      {:noreply,
       socket
       |> assign(:char_draft, draft)
       |> assign(:modal, :appearance)
       |> assign(:modal_errors, [])}
    else
      {:noreply, assign(socket, :modal_errors, errors)}
    end
  end

  # ---------------------------------------------------------------------------
  # Step: Appearance
  # ---------------------------------------------------------------------------

  def handle_event("step_appearance", %{"appearance" => params}, socket) do
    appearance = %{
      "body_type" => params["body_type"] || "medium",
      "hair_style" => params["hair_style"] || "short",
      "hair_color" => params["hair_color"] || "brown",
      "skin_tone" => params["skin_tone"] || "tan",
      "eye_color" => params["eye_color"] || "brown"
    }

    draft = Map.put(socket.assigns.char_draft, "appearance", appearance)

    {:noreply,
     socket |> assign(:char_draft, draft) |> assign(:modal, :scores) |> assign(:modal_errors, [])}
  end

  # ---------------------------------------------------------------------------
  # Step: Ability Scores
  # ---------------------------------------------------------------------------

  def handle_event("step_scores", %{"scores" => params}, socket) do
    scores = %{
      "strength" => to_int(params["strength"], 10),
      "dexterity" => to_int(params["dexterity"], 10),
      "constitution" => to_int(params["constitution"], 10),
      "intelligence" => to_int(params["intelligence"], 10),
      "wisdom" => to_int(params["wisdom"], 10),
      "charisma" => to_int(params["charisma"], 10)
    }

    submitted_values = Map.values(scores) |> Enum.sort()

    errors =
      if submitted_values == Enum.sort(@standard_array) do
        []
      else
        ["Each standard array value (15, 14, 13, 12, 10, 8) must be assigned exactly once."]
      end

    if errors == [] do
      draft = Map.merge(socket.assigns.char_draft, scores)

      {:noreply,
       socket
       |> assign(:char_draft, draft)
       |> assign(:modal, :proficiencies)
       |> assign(:modal_errors, [])}
    else
      {:noreply, assign(socket, :modal_errors, errors)}
    end
  end

  # ---------------------------------------------------------------------------
  # Step: Proficiencies (display + class skill selection)
  # ---------------------------------------------------------------------------

  def handle_event("step_proficiencies", %{"proficiencies" => params}, socket) do
    draft = socket.assigns.char_draft
    class = draft["class"] || "fighter"

    {required_count, _choices} = Map.get(@class_skill_choices, class, {2, []})
    selected = Map.get(params, "skill_choices", []) |> List.wrap()

    errors =
      if length(selected) == required_count do
        []
      else
        ["Select exactly #{required_count} skill#{if required_count != 1, do: "s", else: ""}."]
      end

    if errors == [] do
      all_skills = (draft["bg_skill_proficiencies"] || []) ++ selected
      all_tools = draft["bg_tool_proficiencies"] || []

      updated_draft =
        draft
        |> Map.put("skill_proficiencies", Enum.uniq(all_skills))
        |> Map.put("tool_proficiencies", all_tools)

      {:noreply,
       socket
       |> assign(:char_draft, updated_draft)
       |> assign(:modal, :personality)
       |> assign(:modal_errors, [])}
    else
      {:noreply, assign(socket, :modal_errors, errors)}
    end
  end

  # ---------------------------------------------------------------------------
  # Step: Personality
  # ---------------------------------------------------------------------------

  def handle_event("step_personality", %{"personality" => params}, socket) do
    draft =
      Map.merge(socket.assigns.char_draft, %{
        "personality_traits" => params["personality_traits"] || "",
        "ideals" => params["ideals"] || "",
        "bonds" => params["bonds"] || "",
        "flaws" => params["flaws"] || ""
      })

    {:noreply,
     socket |> assign(:char_draft, draft) |> assign(:modal, :review) |> assign(:modal_errors, [])}
  end

  # ---------------------------------------------------------------------------
  # Create
  # ---------------------------------------------------------------------------

  def handle_event("create_character", _params, socket) do
    user = socket.assigns.current_user
    draft = socket.assigns.char_draft

    attrs =
      draft
      |> Map.drop(["bg_skill_proficiencies", "bg_tool_proficiencies"])
      |> Map.put_new("life_events", [])
      |> Map.put_new("starting_items", [])
      |> Map.put_new("languages", [])
      |> Map.put_new("spells_known", spells_for_class(draft["class"]))

    case Characters.create_character(user.id, attrs) do
      {:ok, _character} ->
        characters = Characters.list_for_user(user.id)

        {:noreply,
         socket
         |> assign(:characters, characters)
         |> assign(:modal, :closed)
         |> assign(:char_draft, %{})}

      {:error, changeset} ->
        errors = format_changeset_errors(changeset)
        {:noreply, assign(socket, :modal_errors, errors)}
    end
  end

  # ---------------------------------------------------------------------------
  # Delete
  # ---------------------------------------------------------------------------

  def handle_event("delete_character", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    Characters.delete_character(user.id, String.to_integer(id))
    characters = Characters.list_for_user(user.id)
    {:noreply, assign(socket, :characters, characters)}
  end

  # ---------------------------------------------------------------------------
  # Template
  # ---------------------------------------------------------------------------

  @impl true
  def render(assigns) do
    ~H"""
    <div class="characters-page" style="max-width: 900px; margin: 0 auto; padding: 2rem;">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
        <h1 style="font-size: 1.8rem; color: #e8d5a0; font-family: serif;">My Characters</h1>
        <button
          phx-click="new_character"
          style="background: #4a6fa5; color: white; border: none; padding: 0.6rem 1.2rem; border-radius: 4px; cursor: pointer; font-size: 1rem;"
        >
          + New Character
        </button>
      </div>

      <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 1.5rem;">
        <div
          :for={char <- @characters}
          style="background: #1a1a2e; border: 1px solid #3a3a5a; border-radius: 8px; padding: 1rem; text-align: center; position: relative;"
        >
          <div style="margin-bottom: 0.5rem;">
            <.character_sprite race={char.race} class_name={char.class} size={96} />
          </div>
          <div style="color: #e8d5a0; font-weight: bold; font-size: 1.05rem;">{char.name}</div>
          <div style="color: #a0a8b8; font-size: 0.85rem; margin-top: 0.2rem;">
            {String.capitalize(char.race)} {String.capitalize(char.class)}
          </div>
          <div style="color: #7a8090; font-size: 0.8rem;">Level {char.level}</div>
          <button
            phx-click="delete_character"
            phx-value-id={char.id}
            data-confirm={"Delete #{char.name}?"}
            style="position: absolute; top: 0.5rem; right: 0.5rem; background: none; border: none; color: #664444; cursor: pointer; font-size: 0.9rem;"
          >
            ×
          </button>
        </div>

        <div
          :if={@characters == []}
          style="grid-column: 1/-1; text-align: center; color: #5a6070; padding: 3rem 0;"
        >
          No characters yet. Create your first one!
        </div>
      </div>
      
    <!-- Creation modal -->
      <div
        :if={@modal != :closed}
        style="position: fixed; inset: 0; background: rgba(0,0,0,0.7); display: flex; align-items: center; justify-content: center; z-index: 100;"
      >
        <div style="background: #1a1a2e; border: 1px solid #4a4a6a; border-radius: 8px; width: 560px; max-height: 90vh; overflow-y: auto; padding: 2rem;">
          <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem;">
            <h2 style="color: #e8d5a0; font-family: serif; font-size: 1.4rem;">
              {modal_title(@modal)}
            </h2>
            <button
              phx-click="close_modal"
              style="background: none; border: none; color: #888; cursor: pointer; font-size: 1.4rem;"
            >
              ×
            </button>
          </div>

          <.step_progress current={@modal} />

          <div
            :if={@modal_errors != []}
            style="background: #3a1a1a; border: 1px solid #7a3a3a; border-radius: 4px; padding: 0.8rem; margin-bottom: 1rem;"
          >
            <p
              :for={err <- @modal_errors}
              style="color: #e07070; margin: 0.2rem 0; font-size: 0.9rem;"
            >
              {err}
            </p>
          </div>

          <.render_step
            modal={@modal}
            draft={@char_draft}
            preview_bg_key={@preview_bg_key}
            preview_appearance={@preview_appearance}
          />
        </div>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Step progress indicator
  # ---------------------------------------------------------------------------

  defp steps, do: [:identity, :appearance, :scores, :proficiencies, :personality, :review]

  defp step_index(step), do: Enum.find_index(steps(), &(&1 == step)) || 0

  def step_progress(assigns) do
    assigns = Map.put(assigns, :steps, steps())

    ~H"""
    <div style="display: flex; gap: 0.4rem; margin-bottom: 1.5rem;">
      <div
        :for={step <- @steps}
        style={"flex: 1; height: 4px; border-radius: 2px; background: #{if step_index(step) <= step_index(@current), do: "#4a6fa5", else: "#2a2a4a"}"}
      />
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Per-step form rendering
  # ---------------------------------------------------------------------------

  def render_step(%{modal: :identity} = assigns) do
    races = [{"Human", "human"}, {"Elf", "elf"}, {"Gnome", "gnome"}]
    classes = [{"Fighter", "fighter"}, {"Wizard", "wizard"}, {"Rogue", "rogue"}]

    alignments = [
      {"Lawful Good", "lawful_good"},
      {"Neutral Good", "neutral_good"},
      {"Chaotic Good", "chaotic_good"},
      {"Lawful Neutral", "lawful_neutral"},
      {"True Neutral", "true_neutral"},
      {"Chaotic Neutral", "chaotic_neutral"},
      {"Lawful Evil", "lawful_evil"},
      {"Neutral Evil", "neutral_evil"},
      {"Chaotic Evil", "chaotic_evil"}
    ]

    backgrounds =
      [{"— None —", ""}] ++
        (Data.Backgrounds.all()
         |> Enum.map(fn {k, bg} -> {bg.name, k} end)
         |> Enum.sort_by(&elem(&1, 0)))

    raw_key = assigns[:preview_bg_key]

    bg_key =
      if raw_key && raw_key != "",
        do: raw_key,
        else: assigns.draft["background"] || ""

    bg = if bg_key != "", do: Data.Backgrounds.get(bg_key), else: nil

    bg_skills_str =
      if bg, do: bg.skill_proficiencies |> Enum.map(&pretty_skill/1) |> Enum.join(", "), else: ""

    bg_tools_str =
      if bg, do: bg.tool_proficiencies |> Enum.map(&pretty_skill/1) |> Enum.join(", "), else: ""

    bg_equipment_str =
      if bg,
        do: bg.starting_equipment |> Enum.map(&pretty_skill/1) |> Enum.join(", "),
        else: ""

    assigns =
      assign(assigns,
        races: races,
        classes: classes,
        alignments: alignments,
        backgrounds: backgrounds,
        bg: bg,
        bg_skills_str: bg_skills_str,
        bg_tools_str: bg_tools_str,
        bg_equipment_str: bg_equipment_str,
        bg_key: bg_key
      )

    ~H"""
    <form phx-submit="step_identity" phx-change="preview_identity">
      <.field label="Character Name" name="identity[name]" type="text" value={@draft["name"] || ""} />
      <.select_field
        label="Race"
        name="identity[race]"
        options={@races}
        value={@draft["race"] || "human"}
      />
      <.select_field
        label="Class"
        name="identity[class]"
        options={@classes}
        value={@draft["class"] || "fighter"}
      />
      <.select_field
        label="Level"
        name="identity[level]"
        options={Enum.map(1..20, &{"Level #{&1}", "#{&1}"})}
        value={"#{@draft["level"] || 1}"}
      />
      <.select_field
        label="Alignment"
        name="identity[alignment]"
        options={@alignments}
        value={@draft["alignment"] || "true_neutral"}
      />
      <.select_field
        label="Background"
        name="identity[background]"
        options={@backgrounds}
        value={@bg_key}
      />

      <div
        :if={@bg}
        style="background: #0d0d1e; border: 1px solid #2a3a4a; border-radius: 6px; padding: 0.9rem; margin-bottom: 1rem; font-size: 0.82rem;"
      >
        <div style="color: #e8d5a0; font-weight: bold; margin-bottom: 0.3rem;">
          {@bg.feature.name}
        </div>
        <div style="color: #8090a8; line-height: 1.4; margin-bottom: 0.6rem;">
          {@bg.feature.description}
        </div>
        <div :if={@bg_skills_str != ""} style="margin-bottom: 0.25rem;">
          <span style="color: #5a6070;">Skills: </span>
          <span style="color: #a0c0a0;">{@bg_skills_str}</span>
        </div>
        <div :if={@bg_tools_str != ""} style="margin-bottom: 0.25rem;">
          <span style="color: #5a6070;">Tools: </span>
          <span style="color: #a0c0a0;">{@bg_tools_str}</span>
        </div>
        <div :if={@bg.languages > 0} style="margin-bottom: 0.25rem;">
          <span style="color: #5a6070;">Languages: </span>
          <span style="color: #a0c0a0;">+{@bg.languages} of your choice</span>
        </div>
        <div :if={@bg_equipment_str != ""}>
          <span style="color: #5a6070;">Equipment: </span>
          <span style="color: #a0c0a0;">{@bg_equipment_str}</span>
        </div>
      </div>

      <.modal_buttons back={false} />
    </form>
    """
  end

  def render_step(%{modal: :appearance} = assigns) do
    body_types = [{"Light", "light"}, {"Medium", "medium"}, {"Heavy", "heavy"}]

    hair_styles = [
      {"Short", "short"},
      {"Long", "long"},
      {"Braided", "braided"},
      {"Wavy", "wavy"},
      {"Shaved", "shaved"}
    ]

    hair_colors = [
      {"Black", "black"},
      {"Brown", "brown"},
      {"Blonde", "blonde"},
      {"Red", "red"},
      {"White", "white"},
      {"Silver", "silver"}
    ]

    skin_tones = [
      {"Pale", "pale"},
      {"Fair", "fair"},
      {"Tan", "tan"},
      {"Brown", "brown"},
      {"Dark", "dark"}
    ]

    eye_colors = [
      {"Brown", "brown"},
      {"Blue", "blue"},
      {"Green", "green"},
      {"Grey", "grey"},
      {"Amber", "amber"},
      {"Violet", "violet"}
    ]

    # Merge saved draft values with live preview (live overrides on change)
    draft_app = assigns.draft["appearance"] || %{}
    live_app = assigns[:preview_appearance] || %{}
    app = Map.merge(draft_app, live_app)

    assigns =
      assign(assigns,
        body_types: body_types,
        hair_styles: hair_styles,
        hair_colors: hair_colors,
        skin_tones: skin_tones,
        eye_colors: eye_colors,
        app: app
      )

    ~H"""
    <form phx-submit="step_appearance" phx-change="preview_appearance">
      <div style="display: flex; gap: 2rem; margin-bottom: 1.5rem;">
        <div style="flex: 1;">
          <.select_field
            label="Body Type"
            name="appearance[body_type]"
            options={@body_types}
            value={@app["body_type"] || "medium"}
          />
          <.select_field
            label="Hair Style"
            name="appearance[hair_style]"
            options={@hair_styles}
            value={@app["hair_style"] || "short"}
          />
          <.select_field
            label="Hair Color"
            name="appearance[hair_color]"
            options={@hair_colors}
            value={@app["hair_color"] || "brown"}
          />
          <.select_field
            label="Skin Tone"
            name="appearance[skin_tone]"
            options={@skin_tones}
            value={@app["skin_tone"] || "tan"}
          />
          <.select_field
            label="Eye Color"
            name="appearance[eye_color]"
            options={@eye_colors}
            value={@app["eye_color"] || "brown"}
          />
        </div>

        <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; width: 100px; gap: 0.75rem;">
          <div style={"transform: scale(#{body_type_scale(@app["body_type"] || "medium")}); transition: transform 0.15s;"}>
            <.character_sprite
              race={@draft["race"] || "human"}
              class_name={@draft["class"] || "fighter"}
              size={96}
            />
          </div>
          <div style="display: flex; gap: 6px; align-items: center;">
            <div
              title={"Hair: #{@app["hair_color"] || "brown"}"}
              style={"width: 14px; height: 14px; border-radius: 50%; background: #{hair_color_css(@app["hair_color"] || "brown")}; border: 1px solid #4a4a6a;"}
            />
            <div
              title={"Skin: #{@app["skin_tone"] || "tan"}"}
              style={"width: 14px; height: 14px; border-radius: 50%; background: #{skin_tone_css(@app["skin_tone"] || "tan")}; border: 1px solid #4a4a6a;"}
            />
            <div
              title={"Eyes: #{@app["eye_color"] || "brown"}"}
              style={"width: 14px; height: 14px; border-radius: 50%; background: #{eye_color_css(@app["eye_color"] || "brown")}; border: 1px solid #4a4a6a;"}
            />
          </div>
        </div>
      </div>
      <.modal_buttons back={true} />
    </form>
    """
  end

  def render_step(%{modal: :scores} = assigns) do
    stats = ~w(strength dexterity constitution intelligence wisdom charisma)
    assigns = assign(assigns, :stats, stats)

    ~H"""
    <form phx-submit="step_scores">
      <p style="color: #a0a8b8; font-size: 0.85rem; margin-bottom: 1rem;">
        Assign each value from the standard array exactly once:
        <strong style="color: #e8d5a0;">15, 14, 13, 12, 10, 8</strong>
      </p>
      <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 0.8rem;">
        <div :for={stat <- @stats}>
          <label style="display: block; color: #c0c8d8; font-size: 0.85rem; margin-bottom: 0.3rem;">
            {String.capitalize(stat)}
          </label>
          <select
            name={"scores[#{stat}]"}
            style="width: 100%; padding: 0.4rem; background: #2a2a4a; border: 1px solid #4a4a6a; border-radius: 4px; color: #e8d5a0;"
          >
            <%= for val <- [8, 10, 12, 13, 14, 15] do %>
              <option value={"#{val}"} selected={to_string(@draft[stat] || "") == to_string(val)}>
                {val}
              </option>
            <% end %>
          </select>
        </div>
      </div>
      <.modal_buttons back={true} />
    </form>
    """
  end

  def render_step(%{modal: :proficiencies} = assigns) do
    class = assigns.draft["class"] || "fighter"
    {required, choices} = Map.get(@class_skill_choices, class, {2, []})
    bg_skills = assigns.draft["bg_skill_proficiencies"] || []
    bg_tools = assigns.draft["bg_tool_proficiencies"] || []
    saving_throws = assigns.draft["saving_throw_proficiencies"] || []

    assigns =
      assign(assigns,
        required: required,
        choices: choices,
        bg_skills: bg_skills,
        bg_tools: bg_tools,
        saving_throws: saving_throws
      )

    ~H"""
    <form phx-submit="step_proficiencies">
      <.prof_section title="Saving Throws" items={@saving_throws} />
      <.prof_section title="Background Skills" items={@bg_skills} />
      <.prof_section title="Background Tools" items={@bg_tools} />

      <div style="margin-bottom: 1.2rem;">
        <p style="color: #c0c8d8; font-size: 0.9rem; margin-bottom: 0.6rem;">
          Class Skills — choose {@required}:
        </p>
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 0.4rem;">
          <label
            :for={skill <- @choices}
            style="display: flex; align-items: center; gap: 0.4rem; color: #c0c8d8; font-size: 0.85rem; cursor: pointer;"
          >
            <input type="checkbox" name="proficiencies[skill_choices][]" value={skill} />
            {pretty_skill(skill)}
          </label>
        </div>
      </div>
      <.modal_buttons back={true} />
    </form>
    """
  end

  def render_step(%{modal: :personality} = assigns) do
    bg_key = assigns.draft["background"]
    bg = if bg_key && bg_key != "", do: Data.Backgrounds.get(bg_key), else: nil

    assigns = assign(assigns, :bg, bg)

    ~H"""
    <form phx-submit="step_personality">
      <.textarea_field
        label="Personality Traits"
        name="personality[personality_traits]"
        value={@draft["personality_traits"] || ""}
        placeholder={bg_suggestion(@bg, :suggested_traits)}
      />
      <.textarea_field
        label="Ideals"
        name="personality[ideals]"
        value={@draft["ideals"] || ""}
        placeholder={bg_suggestion(@bg, :suggested_ideals)}
      />
      <.textarea_field
        label="Bonds"
        name="personality[bonds]"
        value={@draft["bonds"] || ""}
        placeholder={bg_suggestion(@bg, :suggested_bonds)}
      />
      <.textarea_field
        label="Flaws"
        name="personality[flaws]"
        value={@draft["flaws"] || ""}
        placeholder={bg_suggestion(@bg, :suggested_flaws)}
      />
      <.modal_buttons back={true} />
    </form>
    """
  end

  def render_step(%{modal: :review} = assigns) do
    ~H"""
    <div>
      <div style="background: #0d0d1e; border: 1px solid #2a2a4a; border-radius: 6px; padding: 1.2rem; margin-bottom: 1.5rem;">
        <div style="display: flex; gap: 1.5rem; align-items: center; margin-bottom: 1rem;">
          <.character_sprite
            race={@draft["race"] || "human"}
            class_name={@draft["class"] || "fighter"}
            size={80}
          />
          <div>
            <div style="color: #e8d5a0; font-size: 1.3rem; font-weight: bold; font-family: serif;">
              {@draft["name"]}
            </div>
            <div style="color: #a0a8b8; margin-top: 0.3rem;">
              Level {@draft["level"]} {String.capitalize(@draft["race"] || "")} {String.capitalize(
                @draft["class"] || ""
              )}
            </div>
            <div style="color: #7a8090; font-size: 0.85rem;">
              {pretty_alignment(@draft["alignment"] || "")}
            </div>
          </div>
        </div>

        <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 0.5rem; margin-bottom: 0.8rem;">
          <.score_box stat="STR" value={@draft["strength"]} />
          <.score_box stat="DEX" value={@draft["dexterity"]} />
          <.score_box stat="CON" value={@draft["constitution"]} />
          <.score_box stat="INT" value={@draft["intelligence"]} />
          <.score_box stat="WIS" value={@draft["wisdom"]} />
          <.score_box stat="CHA" value={@draft["charisma"]} />
        </div>

        <div :if={@draft["background"]} style="color: #a0a8b8; font-size: 0.85rem;">
          Background: {bg_name(@draft["background"])}
        </div>
      </div>

      <div style="display: flex; gap: 0.8rem; justify-content: flex-end;">
        <button
          phx-click="close_modal"
          type="button"
          style="background: #2a2a4a; color: #a0a8b8; border: 1px solid #4a4a6a; padding: 0.6rem 1.2rem; border-radius: 4px; cursor: pointer;"
        >
          Cancel
        </button>
        <button
          phx-click="back_step"
          type="button"
          style="background: #2a2a4a; color: #a0a8b8; border: 1px solid #4a4a6a; padding: 0.6rem 1.2rem; border-radius: 4px; cursor: pointer;"
        >
          ← Back
        </button>
        <button
          phx-click="create_character"
          type="button"
          style="background: #2a6a3a; color: white; border: none; padding: 0.6rem 1.5rem; border-radius: 4px; cursor: pointer; font-size: 1rem;"
        >
          Create Character
        </button>
      </div>
    </div>
    """
  end

  def render_step(assigns), do: ~H""

  # ---------------------------------------------------------------------------
  # Sub-components
  # ---------------------------------------------------------------------------

  def field(assigns) do
    ~H"""
    <div style="margin-bottom: 0.8rem;">
      <label style="display: block; color: #c0c8d8; font-size: 0.85rem; margin-bottom: 0.3rem;">
        {@label}
      </label>
      <input
        type={@type}
        name={@name}
        value={@value}
        style="width: 100%; padding: 0.4rem 0.6rem; background: #2a2a4a; border: 1px solid #4a4a6a; border-radius: 4px; color: #e8d5a0; box-sizing: border-box;"
      />
    </div>
    """
  end

  def select_field(assigns) do
    ~H"""
    <div style="margin-bottom: 0.8rem;">
      <label style="display: block; color: #c0c8d8; font-size: 0.85rem; margin-bottom: 0.3rem;">
        {@label}
      </label>
      <select
        name={@name}
        style="width: 100%; padding: 0.4rem 0.6rem; background: #2a2a4a; border: 1px solid #4a4a6a; border-radius: 4px; color: #e8d5a0;"
      >
        <%= for {label, val} <- @options do %>
          <option value={val} selected={val == @value}>{label}</option>
        <% end %>
      </select>
    </div>
    """
  end

  def textarea_field(assigns) do
    ~H"""
    <div style="margin-bottom: 0.8rem;">
      <label style="display: block; color: #c0c8d8; font-size: 0.85rem; margin-bottom: 0.3rem;">
        {@label}
      </label>
      <textarea
        name={@name}
        rows="2"
        placeholder={@placeholder}
        style="width: 100%; padding: 0.4rem 0.6rem; background: #2a2a4a; border: 1px solid #4a4a6a; border-radius: 4px; color: #e8d5a0; resize: vertical; box-sizing: border-box; font-family: inherit;"
      ><%= @value %></textarea>
    </div>
    """
  end

  def modal_buttons(%{back: false} = assigns) do
    ~H"""
    <div style="display: flex; justify-content: flex-end; margin-top: 1.5rem;">
      <button
        type="submit"
        style="background: #4a6fa5; color: white; border: none; padding: 0.6rem 1.5rem; border-radius: 4px; cursor: pointer; font-size: 1rem;"
      >
        Next →
      </button>
    </div>
    """
  end

  def modal_buttons(%{back: true} = assigns) do
    ~H"""
    <div style="display: flex; justify-content: space-between; margin-top: 1.5rem;">
      <button
        type="button"
        phx-click="back_step"
        style="background: #2a2a4a; color: #a0a8b8; border: 1px solid #4a4a6a; padding: 0.6rem 1.2rem; border-radius: 4px; cursor: pointer;"
      >
        ← Back
      </button>
      <button
        type="submit"
        style="background: #4a6fa5; color: white; border: none; padding: 0.6rem 1.5rem; border-radius: 4px; cursor: pointer; font-size: 1rem;"
      >
        Next →
      </button>
    </div>
    """
  end

  def prof_section(%{items: []} = assigns), do: ~H""

  def prof_section(assigns) do
    ~H"""
    <div style="margin-bottom: 0.8rem;">
      <p style="color: #c0c8d8; font-size: 0.85rem; margin-bottom: 0.3rem;">{@title}:</p>
      <div style="display: flex; flex-wrap: wrap; gap: 0.4rem;">
        <span
          :for={item <- @items}
          style="background: #2a2a4a; border: 1px solid #3a3a5a; border-radius: 3px; padding: 0.2rem 0.5rem; color: #a0c0a0; font-size: 0.8rem;"
        >
          {pretty_skill(item)}
        </span>
      </div>
    </div>
    """
  end

  def score_box(assigns) do
    mod = if assigns[:value], do: floor((assigns.value - 10) / 2), else: 0

    assigns = Map.put(assigns, :mod, mod)

    ~H"""
    <div style="background: #2a2a4a; border: 1px solid #3a3a5a; border-radius: 4px; padding: 0.4rem; text-align: center;">
      <div style="color: #7a8090; font-size: 0.7rem;">{@stat}</div>
      <div style="color: #e8d5a0; font-size: 1.1rem; font-weight: bold;">{@value || "—"}</div>
      <div style="color: #a0a8b8; font-size: 0.75rem;">
        {if @mod >= 0, do: "+#{@mod}", else: "#{@mod}"}
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp validate_identity(params) do
    errors = []

    errors =
      if String.trim(params["name"] || "") == "", do: ["Name is required." | errors], else: errors

    errors
  end

  defp to_int(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {n, ""} -> n
      _ -> default
    end
  end

  defp to_int(val, _default) when is_integer(val), do: val
  defp to_int(_, default), do: default

  defp spells_for_class("wizard"), do: ["fire_bolt", "mage_hand", "magic_missile", "sleep"]
  defp spells_for_class(_), do: []

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.flat_map(fn {field, msgs} ->
      Enum.map(msgs, &"#{Phoenix.Naming.humanize(field)}: #{&1}")
    end)
  end

  defp modal_title(:identity), do: "Identity"
  defp modal_title(:appearance), do: "Appearance"
  defp modal_title(:scores), do: "Ability Scores"
  defp modal_title(:proficiencies), do: "Proficiencies"
  defp modal_title(:personality), do: "Personality"
  defp modal_title(:review), do: "Review"
  defp modal_title(_), do: ""

  defp pretty_skill(skill) do
    skill
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp pretty_alignment("lawful_good"), do: "Lawful Good"
  defp pretty_alignment("neutral_good"), do: "Neutral Good"
  defp pretty_alignment("chaotic_good"), do: "Chaotic Good"
  defp pretty_alignment("lawful_neutral"), do: "Lawful Neutral"
  defp pretty_alignment("true_neutral"), do: "True Neutral"
  defp pretty_alignment("chaotic_neutral"), do: "Chaotic Neutral"
  defp pretty_alignment("lawful_evil"), do: "Lawful Evil"
  defp pretty_alignment("neutral_evil"), do: "Neutral Evil"
  defp pretty_alignment("chaotic_evil"), do: "Chaotic Evil"
  defp pretty_alignment(a), do: String.replace(a, "_", " ")

  defp bg_name(nil), do: "—"
  defp bg_name(""), do: "—"

  defp bg_name(key) do
    case Data.Backgrounds.get(key) do
      nil -> key
      bg -> bg.name
    end
  end

  defp bg_suggestion(nil, _field), do: ""

  defp bg_suggestion(bg, field) do
    case Map.get(bg, field, []) do
      [] -> ""
      list -> hd(list)
    end
  end

  defp prev_step(:appearance), do: :identity
  defp prev_step(:scores), do: :appearance
  defp prev_step(:proficiencies), do: :scores
  defp prev_step(:personality), do: :proficiencies
  defp prev_step(:review), do: :personality
  defp prev_step(step), do: step

  @hair_colors_css %{
    "black" => "#222222",
    "brown" => "#7b4a2d",
    "blonde" => "#d4b483",
    "red" => "#b24a2a",
    "white" => "#e8e8e8",
    "silver" => "#a0a8b8"
  }
  @skin_tones_css %{
    "pale" => "#f0e0d0",
    "fair" => "#ddb896",
    "tan" => "#c8956c",
    "brown" => "#8b5e3c",
    "dark" => "#4a2e1a"
  }
  @eye_colors_css %{
    "brown" => "#7b4a2d",
    "blue" => "#3a6a9b",
    "green" => "#3a7b4a",
    "grey" => "#8090a0",
    "amber" => "#c87a20",
    "violet" => "#7b3a9b"
  }
  @body_type_scales %{"light" => "0.85", "medium" => "1.0", "heavy" => "1.15"}

  defp hair_color_css(c), do: Map.get(@hair_colors_css, c, "#7b4a2d")
  defp skin_tone_css(t), do: Map.get(@skin_tones_css, t, "#c8956c")
  defp eye_color_css(c), do: Map.get(@eye_colors_css, c, "#7b4a2d")
  defp body_type_scale(t), do: Map.get(@body_type_scales, t, "1.0")
end
