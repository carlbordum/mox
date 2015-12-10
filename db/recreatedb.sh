#!/bin/bash

source ./config.sh

sudo -u postgres dropdb $MOX_DB
sudo -u postgres createdb $MOX_DB
sudo -u postgres psql -c "GRANT ALL ON DATABASE $MOX_DB TO $MOX_USER"
sudo -u postgres psql -d $MOX_DB -f basis/dbserver_prep.sql

# Setup AMQP server settings
sudo -u postgres psql -d $MOX_DB -c "insert into amqp.broker
(host, port, vhost, username, password)
values ('$MOX_AMQP_HOST', $MOX_AMQP_PORT, '$MOX_AMQP_VHOST', '$MOX_AMQP_USER',
'$MOX_AMQP_PASS');"

# Grant mox user privileges to publish to AMQP
sudo -u postgres psql -d $MOX_DB -c "GRANT ALL PRIVILEGES ON SCHEMA amqp TO $MOX_USER;
GRANT SELECT ON ALL TABLES IN SCHEMA amqp TO $MOX_USER;"

# Declare AMQP MOX notifications exchange as type fanout
sudo -u postgres psql -d $MOX_DB -c "SELECT amqp.exchange_declare(1, 'mox.notifications', 'fanout', false, true, false);"

sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -c "CREATE SCHEMA actual_state AUTHORIZATION $MOX_USER "
sudo -u postgres psql -c "ALTER database $MOX_DB SET search_path TO actual_state,public;"
sudo -u postgres psql -c "ALTER database mox SET DATESTYLE to 'ISO, YMD';" #Please notice that the db-tests are run, using a different datestyle
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -c "CREATE SCHEMA test AUTHORIZATION $MOX_USER "
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f basis/common_types.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f funcs/_index_helper_funcs.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f funcs/_subtract_tstzrange.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f funcs/_subtract_tstzrange_arr.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f funcs/_as_valid_registrering_livscyklus_transition.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f funcs/_as_search_match_array.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f funcs/_as_search_ilike_array.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f funcs/_json_object_delete_keys.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f funcs/_amqp_functions.sql





cd ./db-templating/
./generate-sql-tbls-types-funcs-for-oiotype.sh

#Apply patches 
cd ./generated-files/
#klasse
patch --fuzz=3 -i  ../patches/dbtyper-specific_klasse.sql.diff
patch --fuzz=3 -i  ../patches/tbls-specific_klasse.sql.diff
patch --fuzz=3 -i  ../patches/as_create_or_import_klasse.sql.diff
patch --fuzz=3 -i  ../patches/as_list_klasse.sql.diff
patch --fuzz=3 -i  ../patches/as_search_klasse.sql.diff
patch --fuzz=3 -i  ../patches/as_update_klasse.sql.diff
patch --fuzz=3 -i  ../patches/_remove_nulls_in_array_klasse.sql.diff
#sag
patch --fuzz=3 -i  ../patches/tbls-specific_sag.sql.diff
patch --fuzz=3 -i  ../patches/dbtyper-specific_sag.sql.diff
patch --fuzz=3 -i  ../patches/as_list_sag.sql.diff
patch --fuzz=3 -i  ../patches/_remove_nulls_in_array_sag.sql.diff
patch --fuzz=3 -i  ../patches/as_create_or_import_sag.sql.diff
patch --fuzz=3 -i  ../patches/as_update_sag.sql.diff
patch --fuzz=3 -i  ../patches/json-cast-functions_sag.sql.diff
patch --fuzz=3 -i  ../patches/as_search_sag.sql.diff
#dokument
patch --fuzz=3 -i  ../patches/dbtyper-specific_dokument.sql.diff
patch --fuzz=3 -i  ../patches/tbls-specific_dokument.sql.diff
patch --fuzz=3 -i  ../patches/as_create_or_import_dokument.sql.diff
patch --fuzz=3 -i  ../patches/as_update_dokument.sql.diff
patch --fuzz=3 -i  ../patches/_remove_nulls_in_array_dokument.sql.diff
patch --fuzz=3 -i  ../patches/as_list_dokument.sql.diff
patch --fuzz=3 -i  ../patches/json-cast-functions_dokument.sql.diff
patch --fuzz=3 -i  ../patches/as_search_dokument.sql.diff

cd ..

oiotypes=( facet klassifikation klasse bruger interessefaellesskab itsystem organisation organisationenhed organisationfunktion sag dokument )

templates1=( dbtyper-specific tbls-specific _remove_nulls_in_array )


for oiotype in "${oiotypes[@]}"
do
	for template in "${templates1[@]}"
	do
		sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f ./generated-files/${template}_${oiotype}.sql
	done	
done


#Extra functions depending on templated data types 
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f ../funcs/_ensure_document_del_exists_and_get.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f ../funcs/_ensure_document_variant_exists_and_get.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f ../funcs/_ensure_document_variant_and_del_exists_and_get_del.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f ../funcs/_as_list_dokument_varianter.sql


templates2=(  _as_get_prev_registrering _as_create_registrering as_update  as_create_or_import  as_list as_read as_search json-cast-functions _as_filter_unauth )


for oiotype in "${oiotypes[@]}"
do
	for template in "${templates2[@]}"
	do
		sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f ./generated-files/${template}_${oiotype}.sql
	done	
done

cd ..


#Test functions
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_remove_nulls_in_array_klasse.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_common_types_cleable_casts.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_common_types_cleable_casts.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_search_match_array.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_search_ilike_array.sql
#Facet
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_facet_db_schama.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_create_or_import_facet.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_list_facet.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_read_facet.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_search_facet.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_update_facet.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_filter_unauth_facet.sql
#Klasse (BUT testing template-generated code through klasse, IM)
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_update_klasse.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_read_klasse.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_list_klasse.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_search_klasse.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_remove_nulls_in_array_klasse.sql

#itsystem
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_search_itsystem.sql
#sag
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_create_or_import_sag.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_update_sag.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_search_sag.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_json_object_delete_keys.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_json_cast_function.sql
#dokument
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_create_or_import_dokument.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_list_dokument.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_update_dokument.sql
sudo -u $MOX_USER psql -d $MOX_DB -U $MOX_USER -f tests/test_as_search_dokument.sql
