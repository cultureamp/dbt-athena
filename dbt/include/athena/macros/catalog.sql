
{% macro athena__get_catalog(information_schema, schemas) -%}
    {%- set query -%}
        select * from (
            (
                with tables as (

                    select
                        tables.table_catalog as table_database,
                        tables.table_schema as table_schema,
                        tables.table_name as table_name,

                        case
                            when views.table_name is not null
                                then 'view'
                            when table_type = 'BASE TABLE'
                                then 'table'
                            else table_type
                        end as table_type,

                        null as table_owner,
                        null as table_comment

                    from {{ information_schema }}.tables
                    left join {{ information_schema }}.views
                        on tables.table_catalog = views.table_catalog
                        and tables.table_schema = views.table_schema
                        and tables.table_name = views.table_name

                ),

                columns as (

                    select
                        table_catalog as table_database,
                        table_schema as table_schema,
                        table_name as table_name,
                        column_name as column_name,
                        ordinal_position as column_index,
                        data_type as column_type,
                        comment as column_comment

                    from {{ information_schema }}.columns

                )

                select
                    tables.table_database,
                    tables.table_schema,
                    tables.table_name,
                    tables.table_type,
                    tables.table_comment,
                    columns.column_name,
                    columns.column_index,
                    columns.column_type,
                    columns.column_comment,
                    tables.table_owner

                from tables
                join columns
                    on tables."table_database" = columns."table_database"
                    and tables."table_schema" = columns."table_schema"
                    and tables."table_name" = columns."table_name"
                where "columns"."table_schema" != 'information_schema'
                and (
                    {%- for schema in schemas -%}
                    upper (tables."table_schema") = upper ('{{ schema }}') {%- if not loop.last %} or {% endif -%}
                    {%- endfor -%}
                )
            )
        )
  {%- endset -%}

  {{ return(run_query(query)) }}

{%- endmacro %}
