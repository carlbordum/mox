    ROW (
        ROW ( 
            NULL, 
            {{ life_cycle_code|adapt }} :: Livscykluskode,
            {{ user_ref|adapt }}, 
            {{ note|adapt }}
            ) :: RegistreringBase,
        -- states
        {% for state_array in states -%}
        {{ state_array }},
        {% endfor -%}
        -- attributes
        {% for attribute_array in attributes -%}
        {{ attribute_array }},
        {% endfor %}
        -- relations
        {{ relations }}
    ) :: {{ class_name }}RegistreringType
