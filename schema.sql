-- DROP SCHEMA public;

CREATE SCHEMA public AUTHORIZATION pg_database_owner;

COMMENT ON SCHEMA public IS 'standard public schema';

-- DROP SEQUENCE public."LiteLLM_ModelTable_id_seq";

CREATE SEQUENCE public."LiteLLM_ModelTable_id_seq"
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 2147483647
	START 1
	CACHE 1
	NO CYCLE;-- public."LiteLLM_AuditLog" definition

-- Drop table

-- DROP TABLE public."LiteLLM_AuditLog";

CREATE TABLE public."LiteLLM_AuditLog" (
	id text NOT NULL,
	updated_at timestamp(3) DEFAULT CURRENT_TIMESTAMP NOT NULL,
	changed_by text DEFAULT ''::text NOT NULL,
	changed_by_api_key text DEFAULT ''::text NOT NULL,
	"action" text NOT NULL,
	table_name text NOT NULL,
	object_id text NOT NULL,
	before_value jsonb NULL,
	updated_values jsonb NULL,
	CONSTRAINT "LiteLLM_AuditLog_pkey" PRIMARY KEY (id)
);


-- public."LiteLLM_BudgetTable" definition

-- Drop table

-- DROP TABLE public."LiteLLM_BudgetTable";

CREATE TABLE public."LiteLLM_BudgetTable" (
	budget_id text NOT NULL,
	max_budget float8 NULL,
	soft_budget float8 NULL,
	max_parallel_requests int4 NULL,
	tpm_limit int8 NULL,
	rpm_limit int8 NULL,
	model_max_budget jsonb NULL,
	budget_duration text NULL,
	budget_reset_at timestamp(3) NULL,
	created_at timestamp(3) DEFAULT CURRENT_TIMESTAMP NOT NULL,
	created_by text NOT NULL,
	updated_at timestamp(3) DEFAULT CURRENT_TIMESTAMP NOT NULL,
	updated_by text NOT NULL,
	CONSTRAINT "LiteLLM_BudgetTable_pkey" PRIMARY KEY (budget_id)
);


-- public."LiteLLM_Config" definition

-- Drop table

-- DROP TABLE public."LiteLLM_Config";

CREATE TABLE public."LiteLLM_Config" (
	param_name text NOT NULL,
	param_value jsonb NULL,
	CONSTRAINT "LiteLLM_Config_pkey" PRIMARY KEY (param_name)
);


-- public."LiteLLM_ErrorLogs" definition

-- Drop table

-- DROP TABLE public."LiteLLM_ErrorLogs";

CREATE TABLE public."LiteLLM_ErrorLogs" (
	request_id text NOT NULL,
	"startTime" timestamp(3) NOT NULL,
	"endTime" timestamp(3) NOT NULL,
	api_base text DEFAULT ''::text NOT NULL,
	model_group text DEFAULT ''::text NOT NULL,
	litellm_model_name text DEFAULT ''::text NOT NULL,
	model_id text DEFAULT ''::text NOT NULL,
	request_kwargs jsonb DEFAULT '{}'::jsonb NOT NULL,
	exception_type text DEFAULT ''::text NOT NULL,
	exception_string text DEFAULT ''::text NOT NULL,
	status_code text DEFAULT ''::text NOT NULL,
	CONSTRAINT "LiteLLM_ErrorLogs_pkey" PRIMARY KEY (request_id)
);


-- public."LiteLLM_ModelTable" definition

-- Drop table

-- DROP TABLE public."LiteLLM_ModelTable";

CREATE TABLE public."LiteLLM_ModelTable" (
	id serial4 NOT NULL,
	aliases jsonb NULL,
	created_at timestamp(3) DEFAULT CURRENT_TIMESTAMP NOT NULL,
	created_by text NOT NULL,
	updated_at timestamp(3) DEFAULT CURRENT_TIMESTAMP NOT NULL,
	updated_by text NOT NULL,
	CONSTRAINT "LiteLLM_ModelTable_pkey" PRIMARY KEY (id)
);


-- public."LiteLLM_ProxyModelTable" definition

-- Drop table

-- DROP TABLE public."LiteLLM_ProxyModelTable";

CREATE TABLE public."LiteLLM_ProxyModelTable" (
	model_id text NOT NULL,
	model_name text NOT NULL,
	litellm_params jsonb NOT NULL,
	model_info jsonb NULL,
	created_at timestamp(3) DEFAULT CURRENT_TIMESTAMP NOT NULL,
	created_by text NOT NULL,
	updated_at timestamp(3) DEFAULT CURRENT_TIMESTAMP NOT NULL,
	updated_by text NOT NULL,
	CONSTRAINT "LiteLLM_ProxyModelTable_pkey" PRIMARY KEY (model_id)
);


-- public."LiteLLM_SpendLogs" definition

-- Drop table

-- DROP TABLE public."LiteLLM_SpendLogs";

CREATE TABLE public."LiteLLM_SpendLogs" (
	request_id text NOT NULL,
	call_type text NOT NULL,
	api_key text DEFAULT ''::text NOT NULL,
	spend float8 DEFAULT 0.0 NOT NULL,
	total_tokens int4 DEFAULT 0 NOT NULL,
	prompt_tokens int4 DEFAULT 0 NOT NULL,
	completion_tokens int4 DEFAULT 0 NOT NULL,
	"startTime" timestamp(3) NOT NULL,
	"endTime" timestamp(3) NOT NULL,
	"completionStartTime" timestamp(3) NULL,
	model text DEFAULT ''::text NOT NULL,
	model_id text DEFAULT ''::text NULL,
	model_group text DEFAULT ''::text NULL,
	api_base text DEFAULT ''::text NULL,
	"user" text DEFAULT ''::text NULL,
	metadata jsonb DEFAULT '{}'::jsonb NULL,
	cache_hit text DEFAULT ''::text NULL,
	cache_key text DEFAULT ''::text NULL,
	request_tags jsonb DEFAULT '[]'::jsonb NULL,
	team_id text NULL,
	end_user text NULL,
	requester_ip_address text NULL,
	CONSTRAINT "LiteLLM_SpendLogs_pkey" PRIMARY KEY (request_id)
);
CREATE INDEX "LiteLLM_SpendLogs_end_user_idx" ON public."LiteLLM_SpendLogs" USING btree (end_user);
CREATE INDEX "LiteLLM_SpendLogs_startTime_idx" ON public."LiteLLM_SpendLogs" USING btree ("startTime");


-- public."LiteLLM_UserNotifications" definition

-- Drop table

-- DROP TABLE public."LiteLLM_UserNotifications";

CREATE TABLE public."LiteLLM_UserNotifications" (
	request_id text NOT NULL,
	user_id text NOT NULL,
	models _text NULL,
	justification text NOT NULL,
	status text NOT NULL,
	CONSTRAINT "LiteLLM_UserNotifications_pkey" PRIMARY KEY (request_id)
);


-- public."LiteLLM_EndUserTable" definition

-- Drop table

-- DROP TABLE public."LiteLLM_EndUserTable";

CREATE TABLE public."LiteLLM_EndUserTable" (
	user_id text NOT NULL,
	alias text NULL,
	spend float8 DEFAULT 0.0 NOT NULL,
	allowed_model_region text NULL,
	default_model text NULL,
	budget_id text NULL,
	"blocked" bool DEFAULT false NOT NULL,
	CONSTRAINT "LiteLLM_EndUserTable_pkey" PRIMARY KEY (user_id),
	CONSTRAINT "LiteLLM_EndUserTable_budget_id_fkey" FOREIGN KEY (budget_id) REFERENCES public."LiteLLM_BudgetTable"(budget_id) ON DELETE SET NULL ON UPDATE CASCADE
);


-- public."LiteLLM_OrganizationTable" definition

-- Drop table

-- DROP TABLE public."LiteLLM_OrganizationTable";

CREATE TABLE public."LiteLLM_OrganizationTable" (
	organization_id text NOT NULL,
	organization_alias text NOT NULL,
	budget_id text NOT NULL,
	metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
	models _text NULL,
	spend float8 DEFAULT 0.0 NOT NULL,
	model_spend jsonb DEFAULT '{}'::jsonb NOT NULL,
	created_at timestamp(3) DEFAULT CURRENT_TIMESTAMP NOT NULL,
	created_by text NOT NULL,
	updated_at timestamp(3) DEFAULT CURRENT_TIMESTAMP NOT NULL,
	updated_by text NOT NULL,
	CONSTRAINT "LiteLLM_OrganizationTable_pkey" PRIMARY KEY (organization_id),
	CONSTRAINT "LiteLLM_OrganizationTable_budget_id_fkey" FOREIGN KEY (budget_id) REFERENCES public."LiteLLM_BudgetTable"(budget_id) ON DELETE RESTRICT ON UPDATE CASCADE
);


-- public."LiteLLM_TeamMembership" definition

-- Drop table

-- DROP TABLE public."LiteLLM_TeamMembership";

CREATE TABLE public."LiteLLM_TeamMembership" (
	user_id text NOT NULL,
	team_id text NOT NULL,
	spend float8 DEFAULT 0.0 NOT NULL,
	budget_id text NULL,
	CONSTRAINT "LiteLLM_TeamMembership_pkey" PRIMARY KEY (user_id, team_id),
	CONSTRAINT "LiteLLM_TeamMembership_budget_id_fkey" FOREIGN KEY (budget_id) REFERENCES public."LiteLLM_BudgetTable"(budget_id) ON DELETE SET NULL ON UPDATE CASCADE
);


-- public."LiteLLM_TeamTable" definition

-- Drop table

-- DROP TABLE public."LiteLLM_TeamTable";

CREATE TABLE public."LiteLLM_TeamTable" (
	team_id text NOT NULL,
	team_alias text NULL,
	organization_id text NULL,
	admins _text NULL,
	members _text NULL,
	members_with_roles jsonb DEFAULT '{}'::jsonb NOT NULL,
	metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
	max_budget float8 NULL,
	spend float8 DEFAULT 0.0 NOT NULL,
	models _text NULL,
	max_parallel_requests int4 NULL,
	tpm_limit int8 NULL,
	rpm_limit int8 NULL,
	budget_duration text NULL,
	budget_reset_at timestamp(3) NULL,
	"blocked" bool DEFAULT false NOT NULL,
	created_at timestamp(3) DEFAULT CURRENT_TIMESTAMP NOT NULL,
	updated_at timestamp(3) DEFAULT CURRENT_TIMESTAMP NOT NULL,
	model_spend jsonb DEFAULT '{}'::jsonb NOT NULL,
	model_max_budget jsonb DEFAULT '{}'::jsonb NOT NULL,
	model_id int4 NULL,
	CONSTRAINT "LiteLLM_TeamTable_pkey" PRIMARY KEY (team_id),
	CONSTRAINT "LiteLLM_TeamTable_model_id_fkey" FOREIGN KEY (model_id) REFERENCES public."LiteLLM_ModelTable"(id) ON DELETE SET NULL ON UPDATE CASCADE,
	CONSTRAINT "LiteLLM_TeamTable_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public."LiteLLM_OrganizationTable"(organization_id) ON DELETE SET NULL ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "LiteLLM_TeamTable_model_id_key" ON public."LiteLLM_TeamTable" USING btree (model_id);


-- public."LiteLLM_UserTable" definition

-- Drop table

-- DROP TABLE public."LiteLLM_UserTable";

CREATE TABLE public."LiteLLM_UserTable" (
	user_id text NOT NULL,
	user_alias text NULL,
	team_id text NULL,
	organization_id text NULL,
	"password" text NULL,
	teams _text DEFAULT ARRAY[]::text[] NULL,
	user_role text NULL,
	max_budget float8 NULL,
	spend float8 DEFAULT 0.0 NOT NULL,
	user_email text NULL,
	models _text NULL,
	metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
	max_parallel_requests int4 NULL,
	tpm_limit int8 NULL,
	rpm_limit int8 NULL,
	budget_duration text NULL,
	budget_reset_at timestamp(3) NULL,
	allowed_cache_controls _text DEFAULT ARRAY[]::text[] NULL,
	model_spend jsonb DEFAULT '{}'::jsonb NOT NULL,
	model_max_budget jsonb DEFAULT '{}'::jsonb NOT NULL,
	CONSTRAINT "LiteLLM_UserTable_pkey" PRIMARY KEY (user_id),
	CONSTRAINT "LiteLLM_UserTable_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public."LiteLLM_OrganizationTable"(organization_id) ON DELETE SET NULL ON UPDATE CASCADE
);


-- public."LiteLLM_VerificationToken" definition

-- Drop table

-- DROP TABLE public."LiteLLM_VerificationToken";

CREATE TABLE public."LiteLLM_VerificationToken" (
	"token" text NOT NULL,
	key_name text NULL,
	key_alias text NULL,
	soft_budget_cooldown bool DEFAULT false NOT NULL,
	spend float8 DEFAULT 0.0 NOT NULL,
	expires timestamp(3) NULL,
	models _text NULL,
	aliases jsonb DEFAULT '{}'::jsonb NOT NULL,
	config jsonb DEFAULT '{}'::jsonb NOT NULL,
	user_id text NULL,
	team_id text NULL,
	permissions jsonb DEFAULT '{}'::jsonb NOT NULL,
	max_parallel_requests int4 NULL,
	metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
	"blocked" bool NULL,
	tpm_limit int8 NULL,
	rpm_limit int8 NULL,
	max_budget float8 NULL,
	budget_duration text NULL,
	budget_reset_at timestamp(3) NULL,
	allowed_cache_controls _text DEFAULT ARRAY[]::text[] NULL,
	model_spend jsonb DEFAULT '{}'::jsonb NOT NULL,
	model_max_budget jsonb DEFAULT '{}'::jsonb NOT NULL,
	budget_id text NULL,
	created_at timestamp(3) DEFAULT CURRENT_TIMESTAMP NULL,
	updated_at timestamp(3) DEFAULT CURRENT_TIMESTAMP NULL,
	CONSTRAINT "LiteLLM_VerificationToken_pkey" PRIMARY KEY (token),
	CONSTRAINT "LiteLLM_VerificationToken_budget_id_fkey" FOREIGN KEY (budget_id) REFERENCES public."LiteLLM_BudgetTable"(budget_id) ON DELETE SET NULL ON UPDATE CASCADE
);


-- public."LiteLLM_InvitationLink" definition

-- Drop table

-- DROP TABLE public."LiteLLM_InvitationLink";

CREATE TABLE public."LiteLLM_InvitationLink" (
	id text NOT NULL,
	user_id text NOT NULL,
	is_accepted bool DEFAULT false NOT NULL,
	accepted_at timestamp(3) NULL,
	expires_at timestamp(3) NOT NULL,
	created_at timestamp(3) NOT NULL,
	created_by text NOT NULL,
	updated_at timestamp(3) NOT NULL,
	updated_by text NOT NULL,
	CONSTRAINT "LiteLLM_InvitationLink_pkey" PRIMARY KEY (id),
	CONSTRAINT "LiteLLM_InvitationLink_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public."LiteLLM_UserTable"(user_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT "LiteLLM_InvitationLink_updated_by_fkey" FOREIGN KEY (updated_by) REFERENCES public."LiteLLM_UserTable"(user_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT "LiteLLM_InvitationLink_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public."LiteLLM_UserTable"(user_id) ON DELETE RESTRICT ON UPDATE CASCADE
);


-- public."LiteLLM_OrganizationMembership" definition

-- Drop table

-- DROP TABLE public."LiteLLM_OrganizationMembership";

CREATE TABLE public."LiteLLM_OrganizationMembership" (
	user_id text NOT NULL,
	organization_id text NOT NULL,
	user_role text NULL,
	spend float8 DEFAULT 0.0 NULL,
	budget_id text NULL,
	created_at timestamp(3) DEFAULT CURRENT_TIMESTAMP NULL,
	updated_at timestamp(3) DEFAULT CURRENT_TIMESTAMP NULL,
	CONSTRAINT "LiteLLM_OrganizationMembership_pkey" PRIMARY KEY (user_id, organization_id),
	CONSTRAINT "LiteLLM_OrganizationMembership_budget_id_fkey" FOREIGN KEY (budget_id) REFERENCES public."LiteLLM_BudgetTable"(budget_id) ON DELETE SET NULL ON UPDATE CASCADE,
	CONSTRAINT "LiteLLM_OrganizationMembership_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public."LiteLLM_UserTable"(user_id) ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "LiteLLM_OrganizationMembership_user_id_organization_id_key" ON public."LiteLLM_OrganizationMembership" USING btree (user_id, organization_id);


-- public."Last30dKeysBySpend" source

CREATE OR REPLACE VIEW public."Last30dKeysBySpend"
AS SELECT l.api_key,
    v.key_alias,
    v.key_name,
    sum(l.spend) AS total_spend
   FROM "LiteLLM_SpendLogs" l
     LEFT JOIN "LiteLLM_VerificationToken" v ON l.api_key = v.token
  WHERE l."startTime" >= (CURRENT_DATE - '30 days'::interval)
  GROUP BY l.api_key, v.key_alias, v.key_name
  ORDER BY (sum(l.spend)) DESC;


-- public."Last30dModelsBySpend" source

CREATE OR REPLACE VIEW public."Last30dModelsBySpend"
AS SELECT model,
    sum(spend) AS total_spend
   FROM "LiteLLM_SpendLogs"
  WHERE "startTime" >= (CURRENT_DATE - '30 days'::interval) AND model <> ''::text
  GROUP BY model
  ORDER BY (sum(spend)) DESC;


-- public."Last30dTopEndUsersSpend" source

CREATE OR REPLACE VIEW public."Last30dTopEndUsersSpend"
AS SELECT end_user,
    count(*) AS total_events,
    sum(spend) AS total_spend
   FROM "LiteLLM_SpendLogs"
  WHERE end_user <> ''::text AND end_user <> USER AND "startTime" >= (CURRENT_DATE - '30 days'::interval)
  GROUP BY end_user
  ORDER BY (sum(spend)) DESC
 LIMIT 100;


-- public."LiteLLM_VerificationTokenView" source

CREATE OR REPLACE VIEW public."LiteLLM_VerificationTokenView"
AS SELECT v.token,
    v.key_name,
    v.key_alias,
    v.soft_budget_cooldown,
    v.spend,
    v.expires,
    v.models,
    v.aliases,
    v.config,
    v.user_id,
    v.team_id,
    v.permissions,
    v.max_parallel_requests,
    v.metadata,
    v.blocked,
    v.tpm_limit,
    v.rpm_limit,
    v.max_budget,
    v.budget_duration,
    v.budget_reset_at,
    v.allowed_cache_controls,
    v.model_spend,
    v.model_max_budget,
    v.budget_id,
    v.created_at,
    v.updated_at,
    t.spend AS team_spend,
    t.max_budget AS team_max_budget,
    t.tpm_limit AS team_tpm_limit,
    t.rpm_limit AS team_rpm_limit
   FROM "LiteLLM_VerificationToken" v
     LEFT JOIN "LiteLLM_TeamTable" t ON v.team_id = t.team_id;


-- public."MonthlyGlobalSpend" source

CREATE OR REPLACE VIEW public."MonthlyGlobalSpend"
AS SELECT date("startTime") AS date,
    sum(spend) AS spend
   FROM "LiteLLM_SpendLogs"
  WHERE "startTime" >= (CURRENT_DATE - '30 days'::interval)
  GROUP BY (date("startTime"));


-- public."MonthlyGlobalSpendPerKey" source

CREATE OR REPLACE VIEW public."MonthlyGlobalSpendPerKey"
AS SELECT date("startTime") AS date,
    sum(spend) AS spend,
    api_key
   FROM "LiteLLM_SpendLogs"
  WHERE "startTime" >= (CURRENT_DATE - '30 days'::interval)
  GROUP BY (date("startTime")), api_key;


-- public."MonthlyGlobalSpendPerUserPerKey" source

CREATE OR REPLACE VIEW public."MonthlyGlobalSpendPerUserPerKey"
AS SELECT date("startTime") AS date,
    sum(spend) AS spend,
    api_key,
    "user"
   FROM "LiteLLM_SpendLogs"
  WHERE "startTime" >= (CURRENT_DATE - '30 days'::interval)
  GROUP BY (date("startTime")), "user", api_key;


-- public.dailytagspend source

CREATE OR REPLACE VIEW public.dailytagspend
AS SELECT jsonb_array_elements_text(request_tags) AS individual_request_tag,
    date("startTime") AS spend_date,
    count(*) AS log_count,
    sum(spend) AS total_spend
   FROM "LiteLLM_SpendLogs" s
  GROUP BY (jsonb_array_elements_text(request_tags)), (date("startTime"));