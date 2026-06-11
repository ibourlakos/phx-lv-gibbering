# Data Pipeline

```
[Open5e JSON / SRD files]
        │
        ▼
LegalGuard.legally_safe?/1     ← drops WotC Product Identity (Beholder, Mind Flayer, etc.)
        │
        ▼
Pipeline.Parser.parse_action_damage/1  ← regex: "Hit: 10 (2d6+3) piercing" → %{dice_count, ...}
        │
        ▼
[PostgreSQL: monsters, spells tables]
```
