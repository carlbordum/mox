SELECT a::json FROM as_list_{{ class_name | lower }}(
    %(uuid)s::uuid[],
    %(registrering_tstzrange)s,
    %(virkning_tstzrange)s
    ) a;