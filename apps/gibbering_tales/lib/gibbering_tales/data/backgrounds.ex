defmodule GibberingTales.Data.Backgrounds do
  @moduledoc "Seed source and runtime lookup for the backgrounds catalogue table."

  @backgrounds %{
    "acolyte" => %{
      name: "Acolyte",
      description:
        "You have spent your life in service to a temple, learning sacred rites and acting as an intermediary between the mortal world and the gods.",
      skill_proficiencies: ["insight", "religion"],
      tool_proficiencies: [],
      languages: 2,
      starting_equipment: [
        "holy_symbol",
        "prayer_book",
        "incense_x5",
        "vestments",
        "common_clothes",
        "belt_pouch_15gp"
      ],
      feature: %{
        name: "Shelter of the Faithful",
        description:
          "You command the respect of those who share your faith. You can perform religious ceremonies, and temples of your faith will shelter and feed you and your companions."
      },
      suggested_traits: [
        "I idolize a particular hero and constantly reference their deeds.",
        "I see omens in every event — the gods are speaking to those who listen.",
        "I am tolerant of other faiths and always curious about their teachings."
      ],
      suggested_ideals: [
        "Faith. I trust that my deity's guidance will carry me through darkness.",
        "Charity. I help those in need, no matter the cost to myself.",
        "Power. I hope to one day rise to the highest rank in my temple's hierarchy."
      ],
      suggested_bonds: [
        "I would die to recover an ancient relic of my faith.",
        "I will someday get revenge on a corrupt high priest who wronged me.",
        "Everything I do is for the common people of my hometown."
      ],
      suggested_flaws: [
        "I am inflexible in my thinking — there is one right way and it is mine.",
        "I am suspicious of strangers and expect the worst of them.",
        "I put too much trust in those in power within my temple's hierarchy."
      ]
    },
    "charlatan" => %{
      name: "Charlatan",
      description:
        "You have always had a talent for convincing people that black is white and the sky is green. You know how to exploit other people's needs and desires.",
      skill_proficiencies: ["deception", "sleight_of_hand"],
      tool_proficiencies: ["disguise_kit", "forgery_kit"],
      languages: 0,
      starting_equipment: [
        "fine_clothes",
        "disguise_kit",
        "con_tools",
        "belt_pouch_15gp"
      ],
      feature: %{
        name: "False Identity",
        description:
          "You have a second identity — complete with documentation, established acquaintances, and disguises. You can also forge documents, given access to originals."
      },
      suggested_traits: [
        "I fall in and out of love easily and am always pursuing someone.",
        "I have a joke for every occasion, especially when it is inappropriate.",
        "Flattery is my preferred tool when I need someone on my side."
      ],
      suggested_ideals: [
        "Independence. I am a free spirit — no one tells me what to do.",
        "Fairness. I never target people who can't afford to lose a little coin.",
        "Creativity. I never run the same con twice."
      ],
      suggested_bonds: [
        "I fleeced the wrong person and must make it right before they find me.",
        "I owe everything to a mentor who showed me the ropes and saved my life.",
        "Somewhere out there I have a child who doesn't know I exist."
      ],
      suggested_flaws: [
        "I can't resist a pretty face.",
        "I'm convinced that no one could ever fool me the way I fool others.",
        "I'm too greedy for my own good. I can't resist taking a risk if there's money involved."
      ]
    },
    "criminal" => %{
      name: "Criminal",
      description:
        "You are an experienced criminal with a history of breaking the law. You have spent time among thieves, assassins, and enforcers.",
      skill_proficiencies: ["deception", "stealth"],
      tool_proficiencies: ["gaming_set", "thieves_tools"],
      languages: 0,
      starting_equipment: [
        "crowbar",
        "dark_common_clothes_with_hood",
        "belt_pouch_15gp"
      ],
      feature: %{
        name: "Criminal Contact",
        description:
          "You have a reliable and trustworthy contact in the criminal underworld who acts as your liaison to a network of criminals."
      },
      suggested_traits: [
        "I always have a plan for when things go wrong.",
        "I am always calm, no matter the situation. I never raise my voice or let my emotions control me.",
        "The first thing I do in a new place is note the exits — just in case."
      ],
      suggested_ideals: [
        "Honor. I don't steal from others in the trade.",
        "Freedom. Chains are meant to be broken, as are those who forge them.",
        "People. I'm loyal to my friends, not to any ideals."
      ],
      suggested_bonds: [
        "I'm trying to pay off an old debt I owe to a dangerous patron.",
        "I escaped from prison and plan to stay as far as possible from those who would drag me back.",
        "Someone I loved died because of a mistake I made. That will never happen again."
      ],
      suggested_flaws: [
        "When I see something I want, I can't think about anything else until I have it.",
        "I turn tail and run when things look bad.",
        "An innocent person is in prison for a crime I committed. I'm okay with that."
      ]
    },
    "entertainer" => %{
      name: "Entertainer",
      description:
        "You thrive in front of an audience. You know how to entrance them, dazzle them, and make them laugh. Your art is your life.",
      skill_proficiencies: ["acrobatics", "performance"],
      tool_proficiencies: ["disguise_kit", "musical_instrument"],
      languages: 0,
      starting_equipment: [
        "musical_instrument",
        "favor_of_admirer",
        "costume",
        "belt_pouch_15gp"
      ],
      feature: %{
        name: "By Popular Demand",
        description:
          "You can always find a place to perform, usually at a tavern or noble's court. While there, you receive free lodging and food of a modest standard, as long as you perform each night."
      },
      suggested_traits: [
        "I know a story relevant to almost every situation.",
        "Whenever I come to a new place, I collect local songs, legends, and stories.",
        "I'm a hopeless romantic, always searching for that special someone."
      ],
      suggested_ideals: [
        "Beauty. When I perform, I make the world better than it was.",
        "Creativity. The world is in need of new ideas and bold action.",
        "Honesty. Art should reflect the soul; it should come from within and reveal who we really are."
      ],
      suggested_bonds: [
        "My instrument is my most treasured possession and it connects me to my lost love.",
        "Someone stole my precious instrument and someday I'll get it back.",
        "I want to be famous, whatever it takes."
      ],
      suggested_flaws: [
        "I'll do anything to win fame and renown.",
        "I'm a sucker for a pretty face.",
        "A scandal prevents me from ever going home again."
      ]
    },
    "folk_hero" => %{
      name: "Folk Hero",
      description:
        "You come from a humble social rank but are destined for something more. Already the people of your home village regard you as their champion.",
      skill_proficiencies: ["animal_handling", "survival"],
      tool_proficiencies: ["artisan_tools", "vehicles_land"],
      languages: 0,
      starting_equipment: [
        "artisan_tools",
        "shovel",
        "iron_pot",
        "common_clothes",
        "belt_pouch_10gp"
      ],
      feature: %{
        name: "Rustic Hospitality",
        description:
          "Since you come from the ranks of common folk, you fit in among them with ease. You can find a place to hide, rest, or recuperate among ordinary people."
      },
      suggested_traits: [
        "I judge people by their actions, not their words.",
        "If someone is in trouble, I'm always ready to lend help.",
        "I'm confident in my own abilities and do what I can to instill confidence in others."
      ],
      suggested_ideals: [
        "Respect. People deserve to be treated with dignity, regardless of station.",
        "Fairness. No one should get special treatment before the law.",
        "Freedom. Tyrants must not be allowed to oppress the people."
      ],
      suggested_bonds: [
        "I have a family, but I have no idea where they are.",
        "I worked the land, loved the land, and will protect the land.",
        "A proud noble once gave me a horrible beating and I will take revenge on any bully I encounter."
      ],
      suggested_flaws: [
        "The tyrant who rules my land will stop at nothing to see me killed.",
        "I'm convinced of the significance of my destiny and blind to my shortcomings.",
        "The people who knew me when I was young know my shameful secret."
      ]
    },
    "guild_artisan" => %{
      name: "Guild Artisan",
      description:
        "You are a member of an artisan's guild, skilled in a particular field and closely associated with other artisans. Your guild membership has given you connections and resources.",
      skill_proficiencies: ["insight", "persuasion"],
      tool_proficiencies: ["artisan_tools"],
      languages: 1,
      starting_equipment: [
        "artisan_tools",
        "letter_of_introduction",
        "travelers_clothes",
        "belt_pouch_15gp"
      ],
      feature: %{
        name: "Guild Membership",
        description:
          "As a guild member, you can rely on your fellow guild members for lodging and sustenance. In a city, you can find guild halls and members who will help you in times of need."
      },
      suggested_traits: [
        "I believe that anything worth doing is worth doing right.",
        "I'm rude to people who slack off.",
        "I like to talk at length about my profession."
      ],
      suggested_ideals: [
        "Community. It is the duty of all to strengthen the bonds of community.",
        "Generosity. My talents were given to me so that I could use them to benefit the world.",
        "Aspiration. I work hard to be the best there is at my craft."
      ],
      suggested_bonds: [
        "The workshop where I learned my trade is the most important place to me.",
        "I created a great work for someone and then they died before I could give it to them.",
        "I will get revenge on the corrupt merchants who stole my masterpiece."
      ],
      suggested_flaws: [
        "I'll do anything to get my hands on something rare or priceless.",
        "I'm quick to assume that someone is trying to cheat me.",
        "No one must ever learn that I once stole from a guild member."
      ]
    },
    "hermit" => %{
      name: "Hermit",
      description:
        "You lived in seclusion — either in a sheltered community such as a monastery or entirely alone — for a formative part of your life. In your time apart from society, you found quiet and wisdom.",
      skill_proficiencies: ["medicine", "religion"],
      tool_proficiencies: ["herbalism_kit"],
      languages: 1,
      starting_equipment: [
        "scroll_case_with_notes",
        "winter_blanket",
        "common_clothes",
        "herbalism_kit",
        "belt_pouch_5gp"
      ],
      feature: %{
        name: "Discovery",
        description:
          "The quiet of your seclusion gave you access to a unique and powerful discovery — a great truth, a portal, a hidden place, or some other wonder."
      },
      suggested_traits: [
        "I've been isolated so long I rarely speak — I prefer action over words.",
        "I am utterly serene, even in the face of disaster.",
        "The leader of my community had something wise to say on every topic, and I'm determined to find out what it was."
      ],
      suggested_ideals: [
        "Greater Good. My gifts are meant to be shared with all, not used for my own benefit.",
        "Live and Let Live. Meddling in the affairs of others leads only to trouble.",
        "Self-Knowledge. If you know yourself, there's nothing left to know."
      ],
      suggested_bonds: [
        "Nothing is more important than the other members of my hermitage.",
        "I entered seclusion to hide from the ones who might still hunt me. I must someday confront them.",
        "My isolation gave me great insight into a great evil, and I am duty-bound to stop it."
      ],
      suggested_flaws: [
        "I remember every insult and silently plot revenge.",
        "I am dogmatic in my thinking.",
        "I am oblivious to etiquette and social expectations."
      ]
    },
    "noble" => %{
      name: "Noble",
      description:
        "You understand wealth, power, and privilege. You carry a noble title and your family owns land, collects taxes, and wields significant political influence.",
      skill_proficiencies: ["history", "persuasion"],
      tool_proficiencies: ["gaming_set"],
      languages: 1,
      starting_equipment: [
        "fine_clothes",
        "signet_ring",
        "scroll_of_pedigree",
        "belt_pouch_25gp"
      ],
      feature: %{
        name: "Position of Privilege",
        description:
          "Thanks to your noble birth, people are inclined to think the best of you. You are welcome in high society and common folk make every effort to accommodate you."
      },
      suggested_traits: [
        "My eloquent flattery makes everyone I talk to feel like the most wonderful person in the world.",
        "The common folk love me for my kindness and generosity.",
        "I take great pains to always look my best and follow the latest fashions."
      ],
      suggested_ideals: [
        "Responsibility. It is my duty to respect the authority of those above me.",
        "Independence. I must prove that I can handle myself without the family name.",
        "Noble Obligation. It is my duty to protect and care for the people beneath me."
      ],
      suggested_bonds: [
        "I will face any challenge to win the approval of my family.",
        "My house's alliance with another noble family must be sustained at all costs.",
        "Nothing is more important than the other members of my family."
      ],
      suggested_flaws: [
        "I secretly believe that everyone is beneath me.",
        "I hide a truly scandalous secret that could ruin my family forever.",
        "I too often hear veiled insults and threats in every word addressed to me."
      ]
    },
    "outlander" => %{
      name: "Outlander",
      description:
        "You grew up in the wilds, far from civilization and the comforts of town and technology. You have witnessed the migration of herds larger than forests and survived weather that would kill the unprepared.",
      skill_proficiencies: ["athletics", "survival"],
      tool_proficiencies: ["musical_instrument"],
      languages: 1,
      starting_equipment: [
        "staff",
        "hunting_trap",
        "trophy_from_hunt",
        "travelers_clothes",
        "belt_pouch_10gp"
      ],
      feature: %{
        name: "Wanderer",
        description:
          "You have an excellent memory for maps and geography, and you can always recall the general layout of terrain, settlements, and other features around you."
      },
      suggested_traits: [
        "I'm driven by a wanderlust that led me away from home.",
        "I watch over my friends as if they were a litter of newborn pups.",
        "I once ran 25 miles without stopping to warn my clan of an approaching orc horde."
      ],
      suggested_ideals: [
        "Change. Life is like the seasons — in constant change, and we must change with it.",
        "Greater Good. It is each person's responsibility to make the most happiness for the whole tribe.",
        "Glory. I must earn glory in battle, for myself and my clan."
      ],
      suggested_bonds: [
        "My family, clan, or tribe is the most important thing in my life.",
        "An injury to the unspoiled wilderness is an injury to me.",
        "I will bring terrible wrath down on the evildoers who destroyed my homeland."
      ],
      suggested_flaws: [
        "I am too enamored of ale, wine, and other intoxicants.",
        "There's no room for caution in a life lived to the fullest.",
        "I remember every slight and will not forgive until I have taken revenge."
      ]
    },
    "sage" => %{
      name: "Sage",
      description:
        "You spent years learning the lore of the multiverse. You scoured manuscripts, studied scrolls, and listened to the greatest experts on the subjects that interest you.",
      skill_proficiencies: ["arcana", "history"],
      tool_proficiencies: [],
      languages: 2,
      starting_equipment: [
        "bottle_of_black_ink",
        "quill",
        "small_knife",
        "letter_from_colleague",
        "common_clothes",
        "belt_pouch_10gp"
      ],
      feature: %{
        name: "Researcher",
        description:
          "When you attempt to learn or recall a piece of lore, if you do not know the information, you often know where and from whom you can obtain it."
      },
      suggested_traits: [
        "I use polysyllabic words that convey the impression of great erudition.",
        "I've read every book in the world's greatest libraries — or I like to boast that I have.",
        "I'm used to helping out those who aren't as smart as I am."
      ],
      suggested_ideals: [
        "Knowledge. The path to power and self-improvement is through knowledge.",
        "Self-Improvement. The goal of a life of study is the betterment of oneself.",
        "No Limits. Nothing should fetter the infinite possibility inherent in all existence."
      ],
      suggested_bonds: [
        "I have an ancient text that holds terrible secrets that must not fall into the wrong hands.",
        "I work to preserve a library, university, scriptorium, or monastery.",
        "My life's work is a series of tomes related to a specific field of knowledge."
      ],
      suggested_flaws: [
        "I am easily distracted by the promise of information.",
        "Most people scream and run when they see a demon. I stop and take notes on its anatomy.",
        "Unlocking an ancient mystery is worth the price of a civilization."
      ]
    },
    "sailor" => %{
      name: "Sailor",
      description:
        "You sailed on a seagoing vessel for years. In that time, you faced down mighty storms, foul beasts of the deep, and those who wanted to sink your craft to the bottom of the water.",
      skill_proficiencies: ["athletics", "perception"],
      tool_proficiencies: ["navigators_tools", "vehicles_water"],
      languages: 0,
      starting_equipment: [
        "belaying_pin",
        "silk_rope_50ft",
        "lucky_charm",
        "common_clothes",
        "belt_pouch_10gp"
      ],
      feature: %{
        name: "Ship's Passage",
        description:
          "When you need, you can secure free passage on a sailing ship for yourself and your companions. You might sail on the ship you served on, or another vessel."
      },
      suggested_traits: [
        "My friends know they can rely on me, no matter what.",
        "I work hard so that I can play hard when the work is done.",
        "I enjoy sailing into new ports and making new friends over a flagon of ale."
      ],
      suggested_ideals: [
        "Respect. The thing that keeps a ship together is mutual respect between captain and crew.",
        "Fairness. We all do the work, so we all share in the rewards.",
        "Freedom. The sea is freedom — the freedom to go anywhere and do anything."
      ],
      suggested_bonds: [
        "I'm loyal to my captain first, everything else second.",
        "The ship is most important — crewmates and captains come and go.",
        "I'll always remember my first ship."
      ],
      suggested_flaws: [
        "I follow orders, even if I think they're wrong.",
        "I have a weakness for the vices of the port — wine, gambling, and trouble.",
        "Once someone questions my courage, I never back down no matter how dangerous the situation."
      ]
    },
    "soldier" => %{
      name: "Soldier",
      description:
        "War has been your life for as long as you care to remember. You trained as a youth, studied the use of weapons and armor, learned basic survival techniques.",
      skill_proficiencies: ["athletics", "intimidation"],
      tool_proficiencies: ["gaming_set", "vehicles_land"],
      languages: 0,
      starting_equipment: [
        "insignia_of_rank",
        "trophy_from_fallen_enemy",
        "gaming_set",
        "common_clothes",
        "belt_pouch_10gp"
      ],
      feature: %{
        name: "Military Rank",
        description:
          "You have a military rank from your career as a soldier. Soldiers loyal to your former military organization still recognize your authority and will defer to you if of lower rank."
      },
      suggested_traits: [
        "I'm always polite and respectful.",
        "I'm haunted by memories of war. I dream of them in the night.",
        "I face problems head-on. A simple, direct solution is the best path to success."
      ],
      suggested_ideals: [
        "Greater Good. Our lot is to lay down our lives in defense of others.",
        "Responsibility. I do what I must and obey just authority.",
        "Might. In life as in war, the stronger force wins."
      ],
      suggested_bonds: [
        "I would still lay down my life for the people I served with.",
        "Someone saved my life on the battlefield. To this day, I will never leave a friend behind.",
        "My honor is my life."
      ],
      suggested_flaws: [
        "The monstrous enemy we faced in battle still leaves me quivering with fear.",
        "I have little respect for anyone who is not a proven warrior.",
        "I made a terrible mistake in battle that cost many lives, and I would do anything to keep that mistake secret."
      ]
    },
    "urchin" => %{
      name: "Urchin",
      description:
        "You grew up on the streets alone, orphaned, and poor. You had no one to watch over you or to provide for you, so you learned to provide for yourself.",
      skill_proficiencies: ["sleight_of_hand", "stealth"],
      tool_proficiencies: ["disguise_kit", "thieves_tools"],
      languages: 0,
      starting_equipment: [
        "small_knife",
        "map_of_home_city",
        "pet_mouse",
        "token_from_parents",
        "common_clothes",
        "belt_pouch_10gp"
      ],
      feature: %{
        name: "City Secrets",
        description:
          "You know the secret patterns and flows of cities and can find passages through the urban sprawl that others would miss. When not in combat, you and your companions can travel at twice the normal speed through cities."
      },
      suggested_traits: [
        "I hide scraps of food and trinkets away in my pockets.",
        "I ask a lot of questions.",
        "I bluntly say what other people are hinting at or too afraid to say."
      ],
      suggested_ideals: [
        "Respect. All people, rich or poor, deserve respect.",
        "Community. We have to take care of each other, because no one else is going to do it.",
        "Change. The low are lifted up, and the powerful fall. Change is the nature of things."
      ],
      suggested_bonds: [
        "I escaped my life of poverty by robbing an important person, and I'm wanted for it.",
        "No one else should have to suffer the way I did.",
        "I owe my survival to another urchin who taught me to live on the streets."
      ],
      suggested_flaws: [
        "If I'm outnumbered, I will run away from a fight.",
        "Gold seems like a lot of money to me, and I'll do just about anything for more of it.",
        "I will never fully trust anyone other than myself."
      ]
    }
  }

  @doc "Returns all background definitions as a map keyed by string key."
  def all, do: @backgrounds

  @doc "Returns the background definition for the given key, or nil."
  def get(key), do: Map.get(@backgrounds, key)

  @doc "Returns all background string keys."
  def keys, do: Map.keys(@backgrounds)
end
