--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET search_path = public, pg_catalog;

--
-- Name: my_json_to_hstore(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION my_json_to_hstore(json) RETURNS hstore
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
  SELECT hstore(array_agg(key), array_agg(value))
  FROM   json_each_text($1)
$_$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: access_rights; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE access_rights (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    title character varying(255),
    code character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: access_rights_user_roles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE access_rights_user_roles (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    access_right_id uuid,
    user_role_id uuid
);


--
-- Name: account_regions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE account_regions (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    account_id uuid,
    region_id uuid,
    enabled boolean DEFAULT true,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE accounts (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    state character varying(255),
    accountable_objects integer DEFAULT 30,
    organisation_id uuid
);


--
-- Name: adapters; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE adapters (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    type character varying(255) NOT NULL,
    data hstore,
    account_id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    state character varying(255),
    name text
);


--
-- Name: adapters_machine_images; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE adapters_machine_images (
    adapter_id uuid,
    machine_image_id uuid
);


--
-- Name: alerts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE alerts (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    data json,
    read boolean DEFAULT false,
    read_at timestamp without time zone,
    alertable_type character varying(255),
    alert_type character varying(255),
    alertable_id uuid,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: applications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE applications (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying(255),
    description text,
    account_id uuid,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    cost double precision DEFAULT 0
);


--
-- Name: availability_zones; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE availability_zones (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    zone_name character varying(255),
    region_id uuid,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: aws_records; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE aws_records (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    data json,
    provider_vpc_id character varying(255),
    provider_id character varying(255),
    service_type character varying(255),
    account_id uuid,
    adapter_id uuid,
    region_id uuid,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    type character varying(255)
);


--
-- Name: connections; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE connections (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    interface_id uuid,
    remote_interface_id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    internal boolean DEFAULT false
);


--
-- Name: cost_summaries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cost_summaries (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    blended_cost double precision,
    unblended_cost double precision,
    date date,
    environment_id uuid,
    account_id uuid,
    adapter_id uuid,
    type character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: costs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE costs (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    blended_cost double precision,
    unblended_cost double precision,
    availability_zone character varying(255),
    resource_id character varying(255),
    resource_type character varying(255),
    date date,
    type character varying(255),
    service_id uuid,
    environment_id uuid,
    account_id uuid,
    adapter_id uuid,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: environment_adapters; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE environment_adapters (
    id uuid NOT NULL,
    environment_id uuid,
    adapter_id uuid
);


--
-- Name: environment_jobs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE environment_jobs (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    environment_id uuid,
    job_id uuid,
    action character varying(255)
);


--
-- Name: environment_services; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE environment_services (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    environment_id uuid,
    service_id uuid
);


--
-- Name: environment_tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE environment_tags (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    environment_id uuid,
    tag_key character varying(255),
    tag_type character varying(255),
    tag_value character varying(255),
    is_mandatory boolean,
    account_id uuid,
    created_by uuid,
    updated_by uuid,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: environment_vpcs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE environment_vpcs (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    environment_id uuid,
    vpc_id uuid,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: environments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE environments (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name text,
    state text NOT NULL,
    template_id uuid,
    account_id uuid NOT NULL,
    default_adapter_id uuid,
    locked boolean DEFAULT false,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    desired_state text,
    key_id uuid,
    friendly_id text,
    region_id uuid,
    application_id uuid,
    "position" integer,
    created_by uuid,
    updated_by uuid,
    environment_model json,
    tag_id uuid,
    revision double precision DEFAULT 0.0
);


--
-- Name: events; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE events (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    data json,
    type text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    account_id uuid NOT NULL
);


--
-- Name: general_settings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE general_settings (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    naming_convention_enabled boolean DEFAULT false,
    account_id uuid,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    ip_auto_increment_enabled boolean DEFAULT true
);


--
-- Name: group_roles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE group_roles (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying(255),
    resource_id uuid,
    resource_type character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE groups (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name text,
    organisation_id uuid,
    account_id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: groups_roles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE groups_roles (
    group_id uuid,
    group_role_id uuid
);


--
-- Name: groups_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE groups_users (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    user_id uuid,
    group_id uuid
);


--
-- Name: interfaces; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE interfaces (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    service_id uuid,
    name text,
    interface_type text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    depends boolean
);


--
-- Name: internet_gateways; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE internet_gateways (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying(255),
    state character varying(255),
    type character varying(255),
    provider_id character varying(255),
    provider_data json,
    vpc_id uuid,
    account_id uuid,
    adapter_id uuid,
    region_id uuid,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: jobs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE jobs (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    log_id uuid,
    state text,
    bg_id text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: logs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE logs (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    job_id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: machine_images; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE machine_images (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    adapter_id uuid,
    region_id uuid,
    architecture character varying(255),
    description character varying(255),
    image_id character varying(255),
    image_location character varying(255),
    image_state character varying(255),
    image_type character varying(255),
    is_public character varying(255),
    kernel_id character varying(255),
    platform character varying(255),
    ramdisk_id character varying(255),
    root_device_name character varying(255),
    root_device_type character varying(255),
    virtualization_type character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    block_device_mapping text,
    image_owner_alias character varying(255),
    image_owner_id character varying(255),
    product_codes text,
    active boolean DEFAULT true,
    group_key character varying(255),
    group_match character varying(255),
    name character varying(255)
);


--
-- Name: nacls; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE nacls (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    provider_id character varying(255),
    provider_vpc_id character varying(255),
    name character varying(255),
    vpc_id uuid,
    entries json,
    associations json,
    tags json,
    type character varying(255),
    adapter_id uuid,
    provider_data json,
    account_id uuid,
    region_id uuid
);


--
-- Name: organisation_images; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE organisation_images (
    account_id uuid,
    machine_image_id uuid,
    image_id character varying(255),
    region_id uuid,
    instance_types text,
    image_name text,
    image_data json,
    id integer NOT NULL,
    active boolean,
    user_role_ids uuid[] DEFAULT '{}'::uuid[]
);


--
-- Name: organisation_images_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE organisation_images_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organisation_images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE organisation_images_id_seq OWNED BY organisation_images.id;


--
-- Name: organisations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE organisations (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: permissions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE permissions (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    user_id uuid,
    name text,
    subject_class text,
    subject_id uuid,
    action text,
    description text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: protocols; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE protocols (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name text,
    type text,
    description text,
    interface_id uuid,
    data hstore,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: regions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE regions (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    region_name character varying(255),
    adapter_id uuid,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    code character varying(255)
);


--
-- Name: resources; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE resources (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name text,
    data hstore,
    type text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    account_id uuid,
    environment_id uuid,
    region_id uuid,
    adapter_id uuid
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE roles (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name text,
    resource_id uuid,
    resource_type text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    start_date timestamp with time zone,
    end_date timestamp with time zone
);


--
-- Name: route_tables; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE route_tables (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying(255),
    provider_id character varying(255),
    type character varying(255),
    associations text,
    routes text,
    provider_data json,
    vpc_id uuid,
    account_id uuid,
    adapter_id uuid,
    region_id uuid,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    tags json
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: security_groups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE security_groups (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying(255),
    group_id character varying(255),
    owner_id character varying(255),
    type character varying(255),
    description text,
    ip_permissions text,
    provider_data json,
    vpc_id uuid,
    account_id uuid,
    adapter_id uuid,
    region_id uuid,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    ip_permissions_egress text
);


--
-- Name: service_events; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE service_events (
    id integer NOT NULL,
    service_id uuid NOT NULL,
    event character varying(255),
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: service_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE service_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: service_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE service_events_id_seq OWNED BY service_events.id;


--
-- Name: service_naming_defaults; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE service_naming_defaults (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    prefix_service_name character varying(255),
    suffix_service_count integer,
    last_used_number character varying(255),
    created_by character varying(255),
    updated_by character varying(255),
    account_id uuid,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    service_type character varying(255),
    generic_service_type character varying(255)
);


--
-- Name: service_synchronization_histories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE service_synchronization_histories (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying(255),
    state character varying(255),
    provider_type character varying(255),
    generic_type character varying(255),
    provider_id character varying(255),
    provider_vpc_id character varying(255),
    data json,
    provider_data json,
    updates json,
    adapter_id uuid,
    region_id uuid,
    account_id uuid,
    synchronization_id uuid,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: services; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE services (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name text,
    state text NOT NULL,
    data json,
    type text NOT NULL,
    provider_type text,
    adapter_id uuid,
    geometry json,
    account_id uuid,
    provider_data json,
    generic boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    generic_type text,
    parent_id uuid,
    desired_state text,
    friendly_id text,
    region_id uuid,
    vpc_id uuid,
    provider_id character varying(255),
    error_message text,
    service_vpc_id uuid,
    additional_properties json,
    synchronized boolean
);


--
-- Name: snapshots; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE snapshots (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying(255),
    type character varying(255),
    category character varying(255),
    provider_id character varying(255),
    provider_data json,
    description text,
    account_id uuid,
    service_id uuid,
    adapter_id uuid,
    region_id uuid,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    archived boolean DEFAULT false,
    state character varying(255),
    data json,
    error_message text
);


--
-- Name: subnets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE subnets (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    provider_id character varying(255),
    provider_vpc_id character varying(255),
    name character varying(255),
    vpc_id uuid,
    cidr_block text,
    available_ip integer,
    availability_zone character varying(255),
    tags json,
    type character varying(255),
    provider_data json,
    adapter_id uuid,
    account_id uuid,
    region_id uuid
);


--
-- Name: synchronization_settings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE synchronization_settings (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    account_id uuid,
    repeat json,
    sync_time time without time zone,
    auto_sync_to_aws boolean DEFAULT false,
    auto_sync_to_cs_from_aws boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    status json,
    adapters uuid[] DEFAULT '{}'::uuid[]
);


--
-- Name: synchronizations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE synchronizations (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    state_info json,
    account_id uuid,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    friendly_id integer,
    adapter_ids uuid[] DEFAULT '{}'::uuid[],
    region_ids uuid[] DEFAULT '{}'::uuid[]
);


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tags (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    tag_key character varying(255),
    tag_type character varying(255),
    tag_value character varying(255)[] DEFAULT '{}'::character varying[],
    is_mandatory boolean,
    data hstore,
    account_id uuid,
    created_by uuid,
    updated_by uuid,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    state character varying(255)
);


--
-- Name: template_costs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE template_costs (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    region_id uuid,
    data json,
    type character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: template_services; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE template_services (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    template_id uuid NOT NULL,
    service_id uuid NOT NULL
);


--
-- Name: template_vpcs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE template_vpcs (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    template_id uuid,
    vpc_id uuid,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: templates; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE templates (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name text,
    version text,
    state text NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    friendly_id text,
    template_model json,
    region_id uuid,
    adapter_id uuid,
    created_by uuid,
    updated_by uuid,
    revision double precision DEFAULT 0.0 NOT NULL
);


--
-- Name: user_preferences; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_preferences (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    user_id uuid,
    preferences json DEFAULT '{}'::json,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    prefereable_id uuid,
    prefereable_type character varying(255)
);


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_roles (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    account_id uuid
);


--
-- Name: user_roles_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_roles_users (
    id integer NOT NULL,
    user_id uuid,
    user_role_id uuid
);


--
-- Name: user_roles_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_roles_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_roles_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_roles_users_id_seq OWNED BY user_roles_users.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    email text,
    encrypted_password text NOT NULL,
    reset_password_token text,
    sign_in_count integer DEFAULT 0,
    current_sign_in_ip text,
    last_sign_in_ip text,
    authentication_token text NOT NULL,
    name text,
    confirmation_token text,
    unconfirmed_email text,
    invite_token character varying(255),
    username character varying(255),
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    reset_password_sent_at timestamp with time zone,
    remember_created_at timestamp with time zone,
    current_sign_in_at timestamp with time zone,
    last_sign_in_at timestamp with time zone,
    confirmed_at timestamp with time zone,
    confirmation_sent_at timestamp with time zone,
    invited_at timestamp with time zone,
    signed_up boolean,
    state character varying(255),
    account_id uuid,
    show_intro boolean DEFAULT true
);


--
-- Name: users_roles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users_roles (
    user_id uuid,
    role_id uuid
);


--
-- Name: vpcs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE vpcs (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying(255),
    cidr character varying(255),
    vpc_id character varying(255),
    enable_dns_resolution boolean,
    internet_attached boolean,
    tenancy character varying(255),
    provider_data json,
    enabled boolean,
    template_id uuid,
    region_id uuid,
    account_id uuid,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    type character varying(255),
    adapter_id uuid,
    data json,
    state character varying(255),
    synchronized boolean DEFAULT false,
    user_role_ids uuid[] DEFAULT '{}'::uuid[] NOT NULL
);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY organisation_images ALTER COLUMN id SET DEFAULT nextval('organisation_images_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY service_events ALTER COLUMN id SET DEFAULT nextval('service_events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_roles_users ALTER COLUMN id SET DEFAULT nextval('user_roles_users_id_seq'::regclass);


--
-- Name: access_rights_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY access_rights
    ADD CONSTRAINT access_rights_pkey PRIMARY KEY (id);


--
-- Name: access_rights_user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY access_rights_user_roles
    ADD CONSTRAINT access_rights_user_roles_pkey PRIMARY KEY (id);


--
-- Name: account_regions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY account_regions
    ADD CONSTRAINT account_regions_pkey PRIMARY KEY (id);


--
-- Name: accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: adapters_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY adapters
    ADD CONSTRAINT adapters_pkey PRIMARY KEY (id);


--
-- Name: alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (id);


--
-- Name: applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY applications
    ADD CONSTRAINT applications_pkey PRIMARY KEY (id);


--
-- Name: availability_zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY availability_zones
    ADD CONSTRAINT availability_zones_pkey PRIMARY KEY (id);


--
-- Name: aws_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY aws_records
    ADD CONSTRAINT aws_records_pkey PRIMARY KEY (id);


--
-- Name: connections_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY connections
    ADD CONSTRAINT connections_pkey PRIMARY KEY (id);


--
-- Name: cost_summaries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cost_summaries
    ADD CONSTRAINT cost_summaries_pkey PRIMARY KEY (id);


--
-- Name: costs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY costs
    ADD CONSTRAINT costs_pkey PRIMARY KEY (id);


--
-- Name: environment_adapters_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY environment_adapters
    ADD CONSTRAINT environment_adapters_pkey PRIMARY KEY (id);


--
-- Name: environment_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY environment_jobs
    ADD CONSTRAINT environment_jobs_pkey PRIMARY KEY (id);


--
-- Name: environment_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY environment_services
    ADD CONSTRAINT environment_services_pkey PRIMARY KEY (id);


--
-- Name: environment_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY environment_tags
    ADD CONSTRAINT environment_tags_pkey PRIMARY KEY (id);


--
-- Name: environment_vpcs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY environment_vpcs
    ADD CONSTRAINT environment_vpcs_pkey PRIMARY KEY (id);


--
-- Name: environments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY environments
    ADD CONSTRAINT environments_pkey PRIMARY KEY (id);


--
-- Name: events_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: general_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY general_settings
    ADD CONSTRAINT general_settings_pkey PRIMARY KEY (id);


--
-- Name: group_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY group_roles
    ADD CONSTRAINT group_roles_pkey PRIMARY KEY (id);


--
-- Name: groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: groups_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY groups_users
    ADD CONSTRAINT groups_users_pkey PRIMARY KEY (id);


--
-- Name: interfaces_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY interfaces
    ADD CONSTRAINT interfaces_pkey PRIMARY KEY (id);


--
-- Name: internet_gateways_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY internet_gateways
    ADD CONSTRAINT internet_gateways_pkey PRIMARY KEY (id);


--
-- Name: jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY logs
    ADD CONSTRAINT logs_pkey PRIMARY KEY (id);


--
-- Name: machine_images_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY machine_images
    ADD CONSTRAINT machine_images_pkey PRIMARY KEY (id);


--
-- Name: nacls_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY nacls
    ADD CONSTRAINT nacls_pkey PRIMARY KEY (id);


--
-- Name: organisation_images_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY organisation_images
    ADD CONSTRAINT organisation_images_pkey PRIMARY KEY (id);


--
-- Name: organisations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY organisations
    ADD CONSTRAINT organisations_pkey PRIMARY KEY (id);


--
-- Name: permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: protocols_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY protocols
    ADD CONSTRAINT protocols_pkey PRIMARY KEY (id);


--
-- Name: regions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY regions
    ADD CONSTRAINT regions_pkey PRIMARY KEY (id);


--
-- Name: resources_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY resources
    ADD CONSTRAINT resources_pkey PRIMARY KEY (id);


--
-- Name: roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: route_tables_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY route_tables
    ADD CONSTRAINT route_tables_pkey PRIMARY KEY (id);


--
-- Name: security_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY security_groups
    ADD CONSTRAINT security_groups_pkey PRIMARY KEY (id);


--
-- Name: service_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY service_events
    ADD CONSTRAINT service_events_pkey PRIMARY KEY (id);


--
-- Name: service_naming_defaults_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY service_naming_defaults
    ADD CONSTRAINT service_naming_defaults_pkey PRIMARY KEY (id);


--
-- Name: service_synchronization_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY service_synchronization_histories
    ADD CONSTRAINT service_synchronization_histories_pkey PRIMARY KEY (id);


--
-- Name: services_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- Name: snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY snapshots
    ADD CONSTRAINT snapshots_pkey PRIMARY KEY (id);


--
-- Name: subnets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY subnets
    ADD CONSTRAINT subnets_pkey PRIMARY KEY (id);


--
-- Name: synchronization_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY synchronization_settings
    ADD CONSTRAINT synchronization_settings_pkey PRIMARY KEY (id);


--
-- Name: synchronizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY synchronizations
    ADD CONSTRAINT synchronizations_pkey PRIMARY KEY (id);


--
-- Name: tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: template_costs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY template_costs
    ADD CONSTRAINT template_costs_pkey PRIMARY KEY (id);


--
-- Name: template_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY template_services
    ADD CONSTRAINT template_services_pkey PRIMARY KEY (id);


--
-- Name: template_vpcs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY template_vpcs
    ADD CONSTRAINT template_vpcs_pkey PRIMARY KEY (id);


--
-- Name: templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY templates
    ADD CONSTRAINT templates_pkey PRIMARY KEY (id);


--
-- Name: user_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_preferences
    ADD CONSTRAINT user_preferences_pkey PRIMARY KEY (id);


--
-- Name: user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: user_roles_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_roles_users
    ADD CONSTRAINT user_roles_users_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vpcs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY vpcs
    ADD CONSTRAINT vpcs_pkey PRIMARY KEY (id);


--
-- Name: index_access_rights_user_roles_on_right_id_and_role_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_access_rights_user_roles_on_right_id_and_role_id ON access_rights_user_roles USING btree (access_right_id, user_role_id);


--
-- Name: index_access_rights_user_roles_on_user_role_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_access_rights_user_roles_on_user_role_id ON access_rights_user_roles USING btree (user_role_id);


--
-- Name: index_accounts_oses_on_account_id_and_machine_image_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_accounts_oses_on_account_id_and_machine_image_id ON organisation_images USING btree (account_id, machine_image_id);


--
-- Name: index_machine_images_on_image_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_machine_images_on_image_id ON machine_images USING btree (image_id);


--
-- Name: index_roles_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_roles_on_name ON roles USING btree (name);


--
-- Name: index_roles_on_name_and_resource_type_and_resource_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_roles_on_name_and_resource_type_and_resource_id ON roles USING btree (name, resource_type, resource_id);


--
-- Name: index_services_on_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_services_on_state ON services USING btree (state);


--
-- Name: index_users_on_authentication_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_authentication_token ON users USING btree (authentication_token);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON users USING btree (confirmation_token);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_users_roles_on_user_id_and_role_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_roles_on_user_id_and_role_id ON users_roles USING btree (user_id, role_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: adapters_account_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY adapters
    ADD CONSTRAINT adapters_account_id_fk FOREIGN KEY (account_id) REFERENCES accounts(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: connections_interface_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY connections
    ADD CONSTRAINT connections_interface_id_fk FOREIGN KEY (interface_id) REFERENCES interfaces(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: connections_remote_interface_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY connections
    ADD CONSTRAINT connections_remote_interface_id_fk FOREIGN KEY (remote_interface_id) REFERENCES interfaces(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: environment_jobs_environment_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY environment_jobs
    ADD CONSTRAINT environment_jobs_environment_id_fk FOREIGN KEY (environment_id) REFERENCES environments(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: environment_jobs_job_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY environment_jobs
    ADD CONSTRAINT environment_jobs_job_id_fk FOREIGN KEY (job_id) REFERENCES jobs(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: environment_services_environment_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY environment_services
    ADD CONSTRAINT environment_services_environment_id_fk FOREIGN KEY (environment_id) REFERENCES environments(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: environment_services_service_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY environment_services
    ADD CONSTRAINT environment_services_service_id_fk FOREIGN KEY (service_id) REFERENCES services(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: environments_account_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY environments
    ADD CONSTRAINT environments_account_id_fk FOREIGN KEY (account_id) REFERENCES accounts(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: environments_default_adapter_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY environments
    ADD CONSTRAINT environments_default_adapter_id_fk FOREIGN KEY (default_adapter_id) REFERENCES adapters(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: environments_template_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY environments
    ADD CONSTRAINT environments_template_id_fk FOREIGN KEY (template_id) REFERENCES templates(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: events_account_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_account_id_fk FOREIGN KEY (account_id) REFERENCES accounts(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: groups_account_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_account_id_fk FOREIGN KEY (account_id) REFERENCES accounts(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: groups_users_group_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups_users
    ADD CONSTRAINT groups_users_group_id_fk FOREIGN KEY (group_id) REFERENCES groups(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: groups_users_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups_users
    ADD CONSTRAINT groups_users_user_id_fk FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: interfaces_service_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY interfaces
    ADD CONSTRAINT interfaces_service_id_fk FOREIGN KEY (service_id) REFERENCES services(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: logs_job_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY logs
    ADD CONSTRAINT logs_job_id_fk FOREIGN KEY (job_id) REFERENCES jobs(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: protocols_interface_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY protocols
    ADD CONSTRAINT protocols_interface_id_fk FOREIGN KEY (interface_id) REFERENCES interfaces(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: resources_account_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY resources
    ADD CONSTRAINT resources_account_id_fk FOREIGN KEY (account_id) REFERENCES accounts(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: service_events_service_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY service_events
    ADD CONSTRAINT service_events_service_id_fk FOREIGN KEY (service_id) REFERENCES services(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: services_account_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY services
    ADD CONSTRAINT services_account_id_fk FOREIGN KEY (account_id) REFERENCES accounts(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: services_adapter_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY services
    ADD CONSTRAINT services_adapter_id_fk FOREIGN KEY (adapter_id) REFERENCES adapters(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: services_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY services
    ADD CONSTRAINT services_parent_id_fk FOREIGN KEY (parent_id) REFERENCES services(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: template_services_service_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY template_services
    ADD CONSTRAINT template_services_service_id_fk FOREIGN KEY (service_id) REFERENCES services(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: template_services_template_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY template_services
    ADD CONSTRAINT template_services_template_id_fk FOREIGN KEY (template_id) REFERENCES templates(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: templates_account_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY templates
    ADD CONSTRAINT templates_account_id_fk FOREIGN KEY (account_id) REFERENCES accounts(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: users_account_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_account_id_fk FOREIGN KEY (account_id) REFERENCES accounts(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: users_roles_role_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users_roles
    ADD CONSTRAINT users_roles_role_id_fk FOREIGN KEY (role_id) REFERENCES roles(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: users_roles_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users_roles
    ADD CONSTRAINT users_roles_user_id_fk FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20131209231700');

INSERT INTO schema_migrations (version) VALUES ('20131209232930');

INSERT INTO schema_migrations (version) VALUES ('20131210024136');

INSERT INTO schema_migrations (version) VALUES ('20131216002529');

INSERT INTO schema_migrations (version) VALUES ('20131216023111');

INSERT INTO schema_migrations (version) VALUES ('20131216032515');

INSERT INTO schema_migrations (version) VALUES ('20131218050647');

INSERT INTO schema_migrations (version) VALUES ('20131218051940');

INSERT INTO schema_migrations (version) VALUES ('20140106063149');

INSERT INTO schema_migrations (version) VALUES ('20140113001727');

INSERT INTO schema_migrations (version) VALUES ('20140113231303');

INSERT INTO schema_migrations (version) VALUES ('20140113231458');

INSERT INTO schema_migrations (version) VALUES ('20140120034816');

INSERT INTO schema_migrations (version) VALUES ('20140120035033');

INSERT INTO schema_migrations (version) VALUES ('20140121003128');

INSERT INTO schema_migrations (version) VALUES ('20140121054010');

INSERT INTO schema_migrations (version) VALUES ('20140122085421');

INSERT INTO schema_migrations (version) VALUES ('20140122090556');

INSERT INTO schema_migrations (version) VALUES ('20140122090827');

INSERT INTO schema_migrations (version) VALUES ('20140128062642');

INSERT INTO schema_migrations (version) VALUES ('20140128062707');

INSERT INTO schema_migrations (version) VALUES ('20140128100634');

INSERT INTO schema_migrations (version) VALUES ('20140128102533');

INSERT INTO schema_migrations (version) VALUES ('20140128102903');

INSERT INTO schema_migrations (version) VALUES ('20140128223923');

INSERT INTO schema_migrations (version) VALUES ('20140129100928');

INSERT INTO schema_migrations (version) VALUES ('20140130035144');

INSERT INTO schema_migrations (version) VALUES ('20140202114359');

INSERT INTO schema_migrations (version) VALUES ('20140202131218');

INSERT INTO schema_migrations (version) VALUES ('20140202132337');

INSERT INTO schema_migrations (version) VALUES ('20140202132445');

INSERT INTO schema_migrations (version) VALUES ('20140203051625');

INSERT INTO schema_migrations (version) VALUES ('20140209103341');

INSERT INTO schema_migrations (version) VALUES ('20140211131954');

INSERT INTO schema_migrations (version) VALUES ('20140212010306');

INSERT INTO schema_migrations (version) VALUES ('20140212025840');

INSERT INTO schema_migrations (version) VALUES ('20140212093639');

INSERT INTO schema_migrations (version) VALUES ('20140212093846');

INSERT INTO schema_migrations (version) VALUES ('20140212094024');

INSERT INTO schema_migrations (version) VALUES ('20140212094058');

INSERT INTO schema_migrations (version) VALUES ('20140212094224');

INSERT INTO schema_migrations (version) VALUES ('20140212094905');

INSERT INTO schema_migrations (version) VALUES ('20140212094928');

INSERT INTO schema_migrations (version) VALUES ('20140212095015');

INSERT INTO schema_migrations (version) VALUES ('20140212095036');

INSERT INTO schema_migrations (version) VALUES ('20140212095151');

INSERT INTO schema_migrations (version) VALUES ('20140212095250');

INSERT INTO schema_migrations (version) VALUES ('20140212095352');

INSERT INTO schema_migrations (version) VALUES ('20140212095426');

INSERT INTO schema_migrations (version) VALUES ('20140212095509');

INSERT INTO schema_migrations (version) VALUES ('20140212095538');

INSERT INTO schema_migrations (version) VALUES ('20140212095723');

INSERT INTO schema_migrations (version) VALUES ('20140212095739');

INSERT INTO schema_migrations (version) VALUES ('20140212100756');

INSERT INTO schema_migrations (version) VALUES ('20140212101047');

INSERT INTO schema_migrations (version) VALUES ('20140212101214');

INSERT INTO schema_migrations (version) VALUES ('20140212101449');

INSERT INTO schema_migrations (version) VALUES ('20140212101654');

INSERT INTO schema_migrations (version) VALUES ('20140212101939');

INSERT INTO schema_migrations (version) VALUES ('20140212101956');

INSERT INTO schema_migrations (version) VALUES ('20140212102059');

INSERT INTO schema_migrations (version) VALUES ('20140212102109');

INSERT INTO schema_migrations (version) VALUES ('20140212102121');

INSERT INTO schema_migrations (version) VALUES ('20140212102148');

INSERT INTO schema_migrations (version) VALUES ('20140212102201');

INSERT INTO schema_migrations (version) VALUES ('20140212102228');

INSERT INTO schema_migrations (version) VALUES ('20140212102238');

INSERT INTO schema_migrations (version) VALUES ('20140212102306');

INSERT INTO schema_migrations (version) VALUES ('20140212102333');

INSERT INTO schema_migrations (version) VALUES ('20140212102346');

INSERT INTO schema_migrations (version) VALUES ('20140212102439');

INSERT INTO schema_migrations (version) VALUES ('20140212102451');

INSERT INTO schema_migrations (version) VALUES ('20140212102504');

INSERT INTO schema_migrations (version) VALUES ('20140212102519');

INSERT INTO schema_migrations (version) VALUES ('20140212102535');

INSERT INTO schema_migrations (version) VALUES ('20140212102549');

INSERT INTO schema_migrations (version) VALUES ('20140212102614');

INSERT INTO schema_migrations (version) VALUES ('20140212102629');

INSERT INTO schema_migrations (version) VALUES ('20140212102648');

INSERT INTO schema_migrations (version) VALUES ('20140212102700');

INSERT INTO schema_migrations (version) VALUES ('20140212102825');

INSERT INTO schema_migrations (version) VALUES ('20140212103225');

INSERT INTO schema_migrations (version) VALUES ('20140212103319');

INSERT INTO schema_migrations (version) VALUES ('20140212104203');

INSERT INTO schema_migrations (version) VALUES ('20140212104320');

INSERT INTO schema_migrations (version) VALUES ('20140212105423');

INSERT INTO schema_migrations (version) VALUES ('20140212105435');

INSERT INTO schema_migrations (version) VALUES ('20140212105723');

INSERT INTO schema_migrations (version) VALUES ('20140212105733');

INSERT INTO schema_migrations (version) VALUES ('20140212105906');

INSERT INTO schema_migrations (version) VALUES ('20140212105917');

INSERT INTO schema_migrations (version) VALUES ('20140216080953');

INSERT INTO schema_migrations (version) VALUES ('20140216083628');

INSERT INTO schema_migrations (version) VALUES ('20140216103919');

INSERT INTO schema_migrations (version) VALUES ('20140216104151');

INSERT INTO schema_migrations (version) VALUES ('20140216104815');

INSERT INTO schema_migrations (version) VALUES ('20140216130449');

INSERT INTO schema_migrations (version) VALUES ('20140217071541');

INSERT INTO schema_migrations (version) VALUES ('20140217072737');

INSERT INTO schema_migrations (version) VALUES ('20140218041149');

INSERT INTO schema_migrations (version) VALUES ('20140218044719');

INSERT INTO schema_migrations (version) VALUES ('20140313004216');

INSERT INTO schema_migrations (version) VALUES ('20140313235632');

INSERT INTO schema_migrations (version) VALUES ('20140313235642');

INSERT INTO schema_migrations (version) VALUES ('20140313235746');

INSERT INTO schema_migrations (version) VALUES ('20140406101431');

INSERT INTO schema_migrations (version) VALUES ('20140406101935');

INSERT INTO schema_migrations (version) VALUES ('20140406102526');

INSERT INTO schema_migrations (version) VALUES ('20140407000843');

INSERT INTO schema_migrations (version) VALUES ('20140416055627');

INSERT INTO schema_migrations (version) VALUES ('20140416062441');

INSERT INTO schema_migrations (version) VALUES ('20140501120741');

INSERT INTO schema_migrations (version) VALUES ('20140504042813');

INSERT INTO schema_migrations (version) VALUES ('20140504061332');

INSERT INTO schema_migrations (version) VALUES ('20140504064635');

INSERT INTO schema_migrations (version) VALUES ('20140504065129');

INSERT INTO schema_migrations (version) VALUES ('20140504070450');

INSERT INTO schema_migrations (version) VALUES ('20140504071730');

INSERT INTO schema_migrations (version) VALUES ('20140504080940');

INSERT INTO schema_migrations (version) VALUES ('20140504080949');

INSERT INTO schema_migrations (version) VALUES ('20140505003456');

INSERT INTO schema_migrations (version) VALUES ('20140505091825');

INSERT INTO schema_migrations (version) VALUES ('20140505100655');

INSERT INTO schema_migrations (version) VALUES ('20140505101816');

INSERT INTO schema_migrations (version) VALUES ('20140505105631');

INSERT INTO schema_migrations (version) VALUES ('20140505105652');

INSERT INTO schema_migrations (version) VALUES ('20140505105701');

INSERT INTO schema_migrations (version) VALUES ('20140515000114');

INSERT INTO schema_migrations (version) VALUES ('20140516005041');

INSERT INTO schema_migrations (version) VALUES ('20140520003314');

INSERT INTO schema_migrations (version) VALUES ('20140521014711');

INSERT INTO schema_migrations (version) VALUES ('20140606033836');

INSERT INTO schema_migrations (version) VALUES ('20140610043503');

INSERT INTO schema_migrations (version) VALUES ('20140619105722');

INSERT INTO schema_migrations (version) VALUES ('20140620061127');

INSERT INTO schema_migrations (version) VALUES ('20140704021515');

INSERT INTO schema_migrations (version) VALUES ('20140704055916');

INSERT INTO schema_migrations (version) VALUES ('20140704061247');

INSERT INTO schema_migrations (version) VALUES ('20140707095154');

INSERT INTO schema_migrations (version) VALUES ('20140924053914');

INSERT INTO schema_migrations (version) VALUES ('20140924060818');

INSERT INTO schema_migrations (version) VALUES ('20140924061226');

INSERT INTO schema_migrations (version) VALUES ('20140924061517');

INSERT INTO schema_migrations (version) VALUES ('20140924061835');

INSERT INTO schema_migrations (version) VALUES ('20140924061946');

INSERT INTO schema_migrations (version) VALUES ('20140924062250');

INSERT INTO schema_migrations (version) VALUES ('20140925113503');

INSERT INTO schema_migrations (version) VALUES ('20141001063428');

INSERT INTO schema_migrations (version) VALUES ('20141006115655');

INSERT INTO schema_migrations (version) VALUES ('20141015084005');

INSERT INTO schema_migrations (version) VALUES ('20141031082934');

INSERT INTO schema_migrations (version) VALUES ('20141031142716');

INSERT INTO schema_migrations (version) VALUES ('20141101105742');

INSERT INTO schema_migrations (version) VALUES ('20141103135045');

INSERT INTO schema_migrations (version) VALUES ('20141103143936');

INSERT INTO schema_migrations (version) VALUES ('20141107064528');

INSERT INTO schema_migrations (version) VALUES ('20141110044110');

INSERT INTO schema_migrations (version) VALUES ('20141110052159');

INSERT INTO schema_migrations (version) VALUES ('20141111121358');

INSERT INTO schema_migrations (version) VALUES ('20141112151022');

INSERT INTO schema_migrations (version) VALUES ('20141115144115');

INSERT INTO schema_migrations (version) VALUES ('20141115144326');

INSERT INTO schema_migrations (version) VALUES ('20141115144900');

INSERT INTO schema_migrations (version) VALUES ('20141117042550');

INSERT INTO schema_migrations (version) VALUES ('20141117050256');

INSERT INTO schema_migrations (version) VALUES ('20141124150303');

INSERT INTO schema_migrations (version) VALUES ('20141201080140');

INSERT INTO schema_migrations (version) VALUES ('20141202150131');

INSERT INTO schema_migrations (version) VALUES ('20141204144321');

INSERT INTO schema_migrations (version) VALUES ('20141210072324');

INSERT INTO schema_migrations (version) VALUES ('20141212122118');

INSERT INTO schema_migrations (version) VALUES ('20141213111818');

INSERT INTO schema_migrations (version) VALUES ('20141213111842');

INSERT INTO schema_migrations (version) VALUES ('20141217051046');

INSERT INTO schema_migrations (version) VALUES ('20141218070013');

INSERT INTO schema_migrations (version) VALUES ('20141222114958');

INSERT INTO schema_migrations (version) VALUES ('20141222125419');

INSERT INTO schema_migrations (version) VALUES ('20150106110423');

INSERT INTO schema_migrations (version) VALUES ('20150107131807');

INSERT INTO schema_migrations (version) VALUES ('20150109130147');

INSERT INTO schema_migrations (version) VALUES ('20150115125240');

INSERT INTO schema_migrations (version) VALUES ('20150128051258');

INSERT INTO schema_migrations (version) VALUES ('20150128093526');

INSERT INTO schema_migrations (version) VALUES ('20150204100555');

INSERT INTO schema_migrations (version) VALUES ('20150206130728');

INSERT INTO schema_migrations (version) VALUES ('20150209054423');

INSERT INTO schema_migrations (version) VALUES ('20150209125703');

INSERT INTO schema_migrations (version) VALUES ('20150210042345');

INSERT INTO schema_migrations (version) VALUES ('20150211144623');

INSERT INTO schema_migrations (version) VALUES ('20150212091704');

INSERT INTO schema_migrations (version) VALUES ('20150220075237');

INSERT INTO schema_migrations (version) VALUES ('20150227122519');

INSERT INTO schema_migrations (version) VALUES ('20150304160858');

INSERT INTO schema_migrations (version) VALUES ('20150309083515');

INSERT INTO schema_migrations (version) VALUES ('20150316053217');

INSERT INTO schema_migrations (version) VALUES ('20150316112109');

INSERT INTO schema_migrations (version) VALUES ('20150320104550');

INSERT INTO schema_migrations (version) VALUES ('20150330091256');

INSERT INTO schema_migrations (version) VALUES ('20150330092857');

INSERT INTO schema_migrations (version) VALUES ('20150330093754');

INSERT INTO schema_migrations (version) VALUES ('20150331070033');

INSERT INTO schema_migrations (version) VALUES ('20150401100502');

INSERT INTO schema_migrations (version) VALUES ('20150411073909');

INSERT INTO schema_migrations (version) VALUES ('20150411131151');

INSERT INTO schema_migrations (version) VALUES ('20150413052337');

INSERT INTO schema_migrations (version) VALUES ('20150413133618');

INSERT INTO schema_migrations (version) VALUES ('20150414131144');

INSERT INTO schema_migrations (version) VALUES ('20150420091214');

INSERT INTO schema_migrations (version) VALUES ('20150421070946');

INSERT INTO schema_migrations (version) VALUES ('20150424130707');

INSERT INTO schema_migrations (version) VALUES ('20150504102210');

INSERT INTO schema_migrations (version) VALUES ('20150515100022');

INSERT INTO schema_migrations (version) VALUES ('20150525075416');

INSERT INTO schema_migrations (version) VALUES ('20150601091245');

INSERT INTO schema_migrations (version) VALUES ('20150605091755');

INSERT INTO schema_migrations (version) VALUES ('20150609064841');

INSERT INTO schema_migrations (version) VALUES ('20150612101955');

INSERT INTO schema_migrations (version) VALUES ('20150616094416');

INSERT INTO schema_migrations (version) VALUES ('20150617134146');

INSERT INTO schema_migrations (version) VALUES ('20150624135700');

INSERT INTO schema_migrations (version) VALUES ('20150626102559');

INSERT INTO schema_migrations (version) VALUES ('20150626112042');

INSERT INTO schema_migrations (version) VALUES ('20150629080621');

INSERT INTO schema_migrations (version) VALUES ('20150629081145');

INSERT INTO schema_migrations (version) VALUES ('20150629132730');

INSERT INTO schema_migrations (version) VALUES ('20150630172633');

INSERT INTO schema_migrations (version) VALUES ('20150701155134');

INSERT INTO schema_migrations (version) VALUES ('20150702075944');

INSERT INTO schema_migrations (version) VALUES ('20150707122723');

INSERT INTO schema_migrations (version) VALUES ('20150722074907');

INSERT INTO schema_migrations (version) VALUES ('20150723092226');

INSERT INTO schema_migrations (version) VALUES ('20150727102108');

INSERT INTO schema_migrations (version) VALUES ('20150810150220');

INSERT INTO schema_migrations (version) VALUES ('20150812083554');

INSERT INTO schema_migrations (version) VALUES ('20150824095443');

INSERT INTO schema_migrations (version) VALUES ('20150825062407');

INSERT INTO schema_migrations (version) VALUES ('20150831112528');

INSERT INTO schema_migrations (version) VALUES ('20150831115540');

INSERT INTO schema_migrations (version) VALUES ('20150915130957');

INSERT INTO schema_migrations (version) VALUES ('20150929133426');

INSERT INTO schema_migrations (version) VALUES ('20151008095335');

INSERT INTO schema_migrations (version) VALUES ('20151009053009');

INSERT INTO schema_migrations (version) VALUES ('20151009120116');

INSERT INTO schema_migrations (version) VALUES ('20151028071447');

INSERT INTO schema_migrations (version) VALUES ('20151028125003');

