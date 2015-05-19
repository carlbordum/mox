-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.


--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_actual_state_search_facet()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
	new_uuid_A uuid;
	registrering_A FacetRegistreringType;
	actual_registrering_A registreringBase;
	virkEgenskaber_A Virkning;
	virkAnsvarlig_A Virkning;
	virkRedaktoer1_A Virkning;
	virkRedaktoer2_A Virkning;
	virkPubliceret_A Virkning;
	facetEgenskab_A FacetAttrEgenskaberType;
	facetPubliceret_A FacetTilsPubliceretType;
	facetRelAnsvarlig_A FacetRelationType;
	facetRelRedaktoer1_A FacetRelationType;
	facetRelRedaktoer2_A FacetRelationType;
	uuidAnsvarlig_A uuid :=uuid_generate_v4();
	uuidRedaktoer1_A uuid :=uuid_generate_v4();
	uuidRedaktoer2_A uuid :=uuid_generate_v4();
	uuidregistrering_A uuid :=uuid_generate_v4();
	

	new_uuid_B uuid;
	registrering_B FacetRegistreringType;
	actual_registrering_B registreringBase;
	virkEgenskaber_B Virkning;
	virkAnsvarlig_B Virkning;
	virkRedaktoer1_B Virkning;
	virkRedaktoer2_B Virkning;
	virkPubliceret_B Virkning;
	virkpubliceret2_b Virkning;
	facetEgenskab_B FacetAttrEgenskaberType;
	facetPubliceret_B FacetTilsPubliceretType;
	facetPubliceret_B2 FacetTilsPubliceretType;
	facetRelAnsvarlig_B FacetRelationType;
	facetRelRedaktoer1_B FacetRelationType;
	facetRelRedaktoer2_B FacetRelationType;
	uuidAnsvarlig_B uuid :=uuid_generate_v4();
	uuidRedaktoer1_B uuid :=uuid_generate_v4();
	uuidRedaktoer2_B uuid :=uuid_generate_v4();
	uuidregistrering_B uuid :=uuid_generate_v4();


	new_uuid_C uuid;
	registrering_C FacetRegistreringType;
	actual_registrering_C registreringBase;
	virkEgenskaber_C Virkning;
	virkAnsvarlig_C Virkning;
	virkRedaktoer1_C Virkning;
	virkRedaktoer2_C Virkning;
	virkPubliceret_C Virkning;
	virkpubliceret2_C Virkning;
	facetEgenskab_C FacetAttrEgenskaberType;
	facetPubliceret_C FacetTilsPubliceretType;
	facetPubliceret_C2 FacetTilsPubliceretType;
	facetRelAnsvarlig_C FacetRelationType;
	facetRelRedaktoer1_C FacetRelationType;
	facetRelRedaktoer2_C FacetRelationType;
	uuidAnsvarlig_C uuid :=uuid_generate_v4();
	uuidRedaktoer1_C uuid :=uuid_generate_v4();
	uuidRedaktoer2_C uuid :=uuid_generate_v4();
	uuidregistrering_C uuid :=uuid_generate_v4();


	search_result1 uuid[];
	search_result2 uuid[];
	search_result3 uuid[];
	search_result4 uuid[];
	search_result5 uuid[];
	search_result6 uuid[];
	search_result7 uuid[];

	search_registrering_3 FacetRegistreringType;
	search_registrering_4 FacetRegistreringType;
	search_registrering_5 FacetRegistreringType;
	search_registrering_6 FacetRegistreringType;
	search_registrering_7 FacetRegistreringType;

BEGIN


virkEgenskaber_A :=	ROW (
	'[2015-05-12, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;

virkAnsvarlig_A :=	ROW (
	'[2015-05-11, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

virkRedaktoer1_A :=	ROW (
	'[2015-05-10, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx3'
          ) :: Virkning
;


virkRedaktoer2_A :=	ROW (
	'[2015-05-10, 2016-05-10)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx4'
          ) :: Virkning
;


virkPubliceret_A := ROW (
	'[2015-05-18, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx10'
) :: Virkning
;



facetRelAnsvarlig_A := ROW (
	'Ansvarlig'::FacetRelationKode,
		virkAnsvarlig_A,
	uuidAnsvarlig_A
) :: FacetRelationType
;


facetRelRedaktoer1_A := ROW (
	'Redaktoer'::FacetRelationKode,
		virkRedaktoer1_A,
	uuidRedaktoer1_A
) :: FacetRelationType
;



facetRelRedaktoer2_A := ROW (
	'Redaktoer'::FacetRelationKode,
		virkRedaktoer2_A,
	uuidRedaktoer2_A
) :: FacetRelationType
;


facetPubliceret_A := ROW (
virkPubliceret_A,
'Publiceret'
):: FacetTilsPubliceretType
;


facetEgenskab_A := ROW (
'brugervendt_noegle_text1',
   'facetbeskrivelse_text1',
   'facetplan_text1',
   'facetopbygning_text1',
   'facetophavsret_text1',
   'facetsupplement_text1',
   'retskilde_text1',
   virkEgenskaber_A
) :: FacetAttrEgenskaberType
;


registrering_A := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidregistrering_A,
	'Test Note 4') :: registreringBase
	,
ARRAY[facetPubliceret_A]::FacetTilsPubliceretType[],
ARRAY[facetEgenskab_A]::FacetAttrEgenskaberType[],
ARRAY[facetRelAnsvarlig_A,facetRelRedaktoer1_A,facetRelRedaktoer2_A]
) :: FacetRegistreringType
;

new_uuid_A := actual_state_create_or_import_facet(registrering_A);



--*******************


virkEgenskaber_B :=	ROW (
	'[2015-04-12, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;

virkAnsvarlig_B :=	ROW (
	'[2015-04-11, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

virkRedaktoer1_B :=	ROW (
	'[2015-04-10, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx3'
          ) :: Virkning
;


virkRedaktoer2_B :=	ROW (
	'[2015-04-10, 2016-05-10)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx4'
          ) :: Virkning
;

virkPubliceret_B := ROW (
	'[2015-05-18, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx10'
) :: Virkning
;

virkPubliceret2_B := ROW (
	'[2014-05-18, 2015-05-18)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx143'
) :: Virkning
;


facetRelAnsvarlig_B := ROW (
	'Ansvarlig'::FacetRelationKode,
		virkAnsvarlig_B,
	uuidAnsvarlig_B
) :: FacetRelationType
;


facetRelRedaktoer1_B := ROW (
	'Redaktoer'::FacetRelationKode,
		virkRedaktoer1_B,
	uuidRedaktoer1_B
) :: FacetRelationType
;



facetRelRedaktoer2_B := ROW (
	'Redaktoer'::FacetRelationKode,
		virkRedaktoer2_B,
	uuidRedaktoer2_B
) :: FacetRelationType
;


facetPubliceret_B := ROW (
virkPubliceret_B,
'Publiceret'
):: FacetTilsPubliceretType
;

facetPubliceret_B2 := ROW (
virkPubliceret2_B,
'IkkePubliceret'
):: FacetTilsPubliceretType
;


facetEgenskab_B := ROW (
'brugervendt_noegle_text2',
   'facetbeskrivelse_text2',
   'facetplan_text2',
   'facetopbygning_text2',
   'facetophavsret_text2',
   'facetsupplement_text2',
   'retskilde_text2',
   virkEgenskaber_B
) :: FacetAttrEgenskaberType
;


registrering_B := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidregistrering_B,
	'Test Note 5') :: registreringBase
	,
ARRAY[facetPubliceret_B,facetPubliceret_B2]::FacetTilsPubliceretType[],
ARRAY[facetEgenskab_B]::FacetAttrEgenskaberType[],
ARRAY[facetRelAnsvarlig_B,facetRelRedaktoer1_B,facetRelRedaktoer2_B]
) :: FacetRegistreringType
;

new_uuid_B := actual_state_create_or_import_facet(registrering_B);


--***********************************


search_result1 :=actual_state_search_facet(
	null,--TOOD ??
	new_uuid_A,
	null--registrering_A Facetregistrering_AType
	);

RETURN NEXT is(
search_result1,
ARRAY[new_uuid_A]::uuid[],
'simple search on single uuid'
);


search_result2 :=actual_state_search_facet(
	null,--TOOD ??
	null,
	null--registrering_A Facetregistrering_AType
	);

RETURN NEXT is(
search_result2,
ARRAY[new_uuid_A,new_uuid_B]::uuid[],
'search null params'
);


--***********************************
--search on facets that has had the state not published at any point in time

search_registrering_3 := ROW (
	ROW (
	NULL,
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	ARRAY[
			ROW(
				  ROW(
				  	null,null,null,null
				  	)::virkning 
				  ,'IkkePubliceret'::FacetTilsPubliceretStatus
				):: FacetTilsPubliceretType
	],--ARRAY[facetPubliceret_B]::FacetTilsPubliceretType[],
null,--ARRAY[facetEgenskab_B]::FacetAttrEgenskaberType[],
null--ARRAY[facetRelAnsvarlig_B,facetRelRedaktoer1_B,facetRelRedaktoer2_B]
):: FacetRegistreringType;

--raise notice 'search_registrering_3,%',search_registrering_3;

search_result3 :=actual_state_search_facet(
	null,--TOOD ??
	null,
	search_registrering_3 --registrering_A Facetregistrering_AType
	);

--raise notice 'search for IkkePubliceret returned:%',search_result3;

RETURN NEXT is(
search_result3,
ARRAY[new_uuid_B]::uuid[],
'search state FacetTilsPubliceretStatus IkkePubliceret'
);

--***********************************
--search on facets that were published on 18-05-2015
search_registrering_4 := ROW (
	ROW (
	NULL,
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	ARRAY[
			ROW(
				  ROW(
				  	'[2015-05-18, 2015-05-19]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning 
				  ,'Publiceret'::FacetTilsPubliceretStatus
				):: FacetTilsPubliceretType
	],--ARRAY[facetPubliceret_B]::FacetTilsPubliceretType[],
null,--ARRAY[facetEgenskab_B]::FacetAttrEgenskaberType[],
null--ARRAY[facetRelAnsvarlig_B,facetRelRedaktoer1_B,facetRelRedaktoer2_B]
):: FacetRegistreringType;



search_result4 :=actual_state_search_facet(
	null,--TOOD ??
	null,
	search_registrering_4 --registrering_A Facetregistrering_AType
	);

RETURN NEXT is(
search_result4,
ARRAY[new_uuid_A,new_uuid_B]::uuid[],
'search state FacetTilsPubliceretStatus Publiceret on 18-05-2015 - 19-05-2015'
);


--***********************************
--search on facets that had state 'ikkepubliceret' on 30-06-2015 30-07-2015
search_registrering_5 := ROW (
	ROW (
	NULL,
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	ARRAY[
			ROW(
				  ROW(
				  	'[2015-06-30, 2015-07-30]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning 
				  ,'IkkePubliceret'::FacetTilsPubliceretStatus
				):: FacetTilsPubliceretType
	],--ARRAY[facetPubliceret_B]::FacetTilsPubliceretType[],
null,--ARRAY[facetEgenskab_B]::FacetAttrEgenskaberType[],
null--ARRAY[facetRelAnsvarlig_B,facetRelRedaktoer1_B,facetRelRedaktoer2_B]
):: FacetRegistreringType;



search_result5 :=actual_state_search_facet(
	null,--TOOD ??
	null,
	search_registrering_5 --registrering_A Facetregistrering_AType
	);

RETURN NEXT is(
search_result5,
ARRAY[]::uuid[],
'search state FacetTilsPubliceretStatus ikkepubliceret on 30-06-2015 30-07-2015'
);

--***********************************
--search on facets with specific aktoerref and state publiceret
search_registrering_6 := ROW (
	ROW (
	NULL,
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	ARRAY[
			ROW(
				  ROW(
				  	'[2015-05-18, 2015-05-19]' :: TSTZRANGE,
				  	(virkPubliceret_B).AktoerRef,
				  	null,null
				  	)::virkning 
				  ,'Publiceret'::FacetTilsPubliceretStatus
				):: FacetTilsPubliceretType
	],--ARRAY[facetPubliceret_B]::FacetTilsPubliceretType[],
null,--ARRAY[facetEgenskab_B]::FacetAttrEgenskaberType[],
null--ARRAY[facetRelAnsvarlig_B,facetRelRedaktoer1_B,facetRelRedaktoer2_B]
):: FacetRegistreringType;

search_result6 :=actual_state_search_facet(
	null,--TOOD ??
	null,
	search_registrering_6 --registrering_A Facetregistrering_AType
	);

RETURN NEXT is(
search_result6,
ARRAY[new_uuid_B]::uuid[],
'search on facets with specific aktoerref and state publiceret'
);


--*******************


virkEgenskaber_C :=	ROW (
	'[2014-09-12, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;

virkAnsvarlig_C :=	ROW (
	'[2014-08-11, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

virkRedaktoer1_C :=	ROW (
	'[2014-07-10, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx3'
          ) :: Virkning
;


virkRedaktoer2_C :=	ROW (
	'[2013-04-10, 2015-05-10)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx4'
          ) :: Virkning
;

virkPubliceret_C := ROW (
	'[2015-02-18, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx10'
) :: Virkning
;

virkPubliceret2_C := ROW (
	'[2013-05-18, 2015-02-18)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx143'
) :: Virkning
;


facetRelAnsvarlig_C := ROW (
	'Ansvarlig'::FacetRelationKode,
		virkAnsvarlig_C,
	uuidAnsvarlig_C
) :: FacetRelationType
;


facetRelRedaktoer1_C := ROW (
	'Redaktoer'::FacetRelationKode,
		virkRedaktoer1_C,
	uuidRedaktoer1_C
) :: FacetRelationType
;



facetPubliceret_C := ROW (
virkPubliceret_C,
'Publiceret'
):: FacetTilsPubliceretType
;

facetPubliceret_C2 := ROW (
virkPubliceret2_C,
'IkkePubliceret'
):: FacetTilsPubliceretType
;


facetEgenskab_C := ROW (
'brugervendt_noegle_text3',
   'facetbeskrivelse_text3',
   'facetplan_text3',
   'facetopbygning_text3',
   'facetophavsret_text3',
   'facetsupplement_text3',
   'retskilde_text3',
   virkEgenskaber_C
) :: FacetAttrEgenskaberType
;


registrering_C := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidregistrering_C,
	'Test Note 993') :: registreringBase
	,
ARRAY[facetPubliceret_C,facetPubliceret_C2]::FacetTilsPubliceretType[],
ARRAY[facetEgenskab_C]::FacetAttrEgenskaberType[],
ARRAY[facetRelAnsvarlig_C,facetRelRedaktoer1_C]
) :: FacetRegistreringType
;

new_uuid_C := actual_state_create_or_import_facet(registrering_C);

--*******************
--Do a test, that filters on publiceretStatus, egenskaber and relationer

--search on facets that were published on 18-05-2015
search_registrering_7 := ROW (
	ROW (
	NULL,
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	ARRAY[
			ROW(
				  ROW(
				  	'[2015-05-18, 2015-05-19]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning 
				  ,'Publiceret'::FacetTilsPubliceretStatus
				):: FacetTilsPubliceretType
	],--ARRAY[facetPubliceret_B]::FacetTilsPubliceretType[],
ARRAY[
	ROW(
		NULL,
   		NULL,
        NULL,
   		NULL,
   		NULL,
   		'facetsupplement_text3',
   		NULL,
   			ROW(
				  	'[2015-01-01, 2015-02-01]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning 
		)::FacetAttrEgenskaberType
]::FacetAttrEgenskaberType[],
ARRAY[
	ROW (
	'Redaktoer'::FacetRelationKode,
		ROW(
				'[2013-05-01, 2015-04-11]' :: TSTZRANGE,
				 null,null,null
			)::virkning ,
			null
	) :: FacetRelationType
]
):: FacetRegistreringType;



search_result7 :=actual_state_search_facet(
	null,--TOOD ??
	null,
	search_registrering_7 --registrering_A Facetregistrering_AType
	);

RETURN NEXT is(
search_result7,
ARRAY[new_uuid_C]::uuid[],
'search state publiceretStatus, egenskaber and relationer combined'
);








--TODO Test for different scenarios









END;
$$;