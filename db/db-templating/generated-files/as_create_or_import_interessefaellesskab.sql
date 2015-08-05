-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py interessefaellesskab as_create_or_import.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_create_or_import_interessefaellesskab(
  interessefaellesskab_registrering InteressefaellesskabRegistreringType,
  interessefaellesskab_uuid uuid DEFAULT NULL
	)
  RETURNS uuid AS 
$$
DECLARE
  interessefaellesskab_registrering_id bigint;
  interessefaellesskab_attr_egenskaber_obj interessefaellesskabEgenskaberAttrType;
  
  interessefaellesskab_tils_gyldighed_obj interessefaellesskabGyldighedTilsType;
  
  interessefaellesskab_relationer InteressefaellesskabRelationType;

BEGIN

IF interessefaellesskab_uuid IS NULL THEN
    LOOP
    interessefaellesskab_uuid:=uuid_generate_v4();
    EXIT WHEN NOT EXISTS (SELECT id from interessefaellesskab WHERE id=interessefaellesskab_uuid); 
    END LOOP;
END IF;


IF EXISTS (SELECT id from interessefaellesskab WHERE id=interessefaellesskab_uuid) THEN
  RAISE EXCEPTION 'Error creating or importing interessefaellesskab with uuid [%]. If you did not supply the uuid when invoking as_create_or_import_interessefaellesskab (i.e. create operation) please try to repeat the invocation/operation, that id collison with randomly generated uuids might in theory occur, albeit very very very rarely.',interessefaellesskab_uuid;
END IF;

IF  (interessefaellesskab_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and (interessefaellesskab_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking as_create_or_import_interessefaellesskab.',(interessefaellesskab_registrering.registrering).livscykluskode;
END IF;



INSERT INTO 
      interessefaellesskab (ID)
SELECT
      interessefaellesskab_uuid
;


/*********************************/
--Insert new registrering

interessefaellesskab_registrering_id:=nextval('interessefaellesskab_registrering_id_seq');

INSERT INTO interessefaellesskab_registrering (
      id,
        interessefaellesskab_id,
          registrering
        )
SELECT
      interessefaellesskab_registrering_id,
        interessefaellesskab_uuid,
          ROW (
            TSTZRANGE(clock_timestamp(),'infinity'::TIMESTAMPTZ,'[)' ),
            (interessefaellesskab_registrering.registrering).livscykluskode,
            (interessefaellesskab_registrering.registrering).brugerref,
            (interessefaellesskab_registrering.registrering).note
              ):: RegistreringBase
;

/*********************************/
--Insert attributes


/************/
--Verification
--For now all declared attributes are mandatory (the fields are all optional,though)

 
IF coalesce(array_length(interessefaellesskab_registrering.attrEgenskaber, 1),0)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [egenskaber] for [interessefaellesskab]. Oprettelse afbrydes.';
END IF;



IF interessefaellesskab_registrering.attrEgenskaber IS NOT NULL THEN
  FOREACH interessefaellesskab_attr_egenskaber_obj IN ARRAY interessefaellesskab_registrering.attrEgenskaber
  LOOP

  IF
  ( interessefaellesskab_attr_egenskaber_obj.brugervendtnoegle IS NOT NULL AND interessefaellesskab_attr_egenskaber_obj.brugervendtnoegle<>'') 
   OR 
  ( interessefaellesskab_attr_egenskaber_obj.interessefaellesskabsnavn IS NOT NULL AND interessefaellesskab_attr_egenskaber_obj.interessefaellesskabsnavn<>'') 
   OR 
  ( interessefaellesskab_attr_egenskaber_obj.interessefaellesskabstype IS NOT NULL AND interessefaellesskab_attr_egenskaber_obj.interessefaellesskabstype<>'') 
   THEN

    INSERT INTO interessefaellesskab_attr_egenskaber (
      brugervendtnoegle,
      interessefaellesskabsnavn,
      interessefaellesskabstype,
      virkning,
      interessefaellesskab_registrering_id
    )
    SELECT
     interessefaellesskab_attr_egenskaber_obj.brugervendtnoegle,
      interessefaellesskab_attr_egenskaber_obj.interessefaellesskabsnavn,
      interessefaellesskab_attr_egenskaber_obj.interessefaellesskabstype,
      interessefaellesskab_attr_egenskaber_obj.virkning,
      interessefaellesskab_registrering_id
    ;
  END IF;

  END LOOP;
END IF;

/*********************************/
--Insert states (tilstande)


--Verification
--For now all declared states are mandatory.
IF coalesce(array_length(interessefaellesskab_registrering.tilsGyldighed, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [gyldighed] for interessefaellesskab. Oprettelse afbrydes.';
END IF;

IF interessefaellesskab_registrering.tilsGyldighed IS NOT NULL THEN
  FOREACH interessefaellesskab_tils_gyldighed_obj IN ARRAY interessefaellesskab_registrering.tilsGyldighed
  LOOP

  IF interessefaellesskab_tils_gyldighed_obj.gyldighed IS NOT NULL AND interessefaellesskab_tils_gyldighed_obj.gyldighed<>''::InteressefaellesskabGyldighedTils THEN

    INSERT INTO interessefaellesskab_tils_gyldighed (
      virkning,
      gyldighed,
      interessefaellesskab_registrering_id
    )
    SELECT
      interessefaellesskab_tils_gyldighed_obj.virkning,
      interessefaellesskab_tils_gyldighed_obj.gyldighed,
      interessefaellesskab_registrering_id;

  END IF;
  END LOOP;
END IF;

/*********************************/
--Insert relations

    INSERT INTO interessefaellesskab_relation (
      interessefaellesskab_registrering_id,
      virkning,
      rel_maal_uuid,
      rel_maal_urn,
      rel_type,
      objekt_type
    )
    SELECT
      interessefaellesskab_registrering_id,
      a.virkning,
      a.relMaalUuid,
      a.relMaalUrn,
      a.relType,
      a.objektType
    FROM unnest(interessefaellesskab_registrering.relationer) a
    WHERE (a.relMaalUuid IS NOT NULL OR (a.relMaalUrn IS NOT NULL AND a.relMaalUrn<>'') )
  ;

  PERFORM amqp.publish(1, 'mox.notifications', '', format('create %s', interessefaellesskab_uuid));

RETURN interessefaellesskab_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


