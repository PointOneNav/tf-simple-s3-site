# AGENTS.md — tf-simple-s3-site

OpenTofu/Terraform module for a static S3 site fronted by CloudFront.

## Tooling

- Uses **OpenTofu** (`tofu`). The lockfile is maintained by `tofu init`.
  Terraform works too but `tofu` is canonical.
- AWS provider `>= 5.42.0`.

## Commands

```sh
tofu init                                   # first use or after adding providers
tofu validate                               # validate root module (fails — needs alias)
tofu -chdir=examples/simple init && \
  tofu -chdir=examples/simple validate      # validate module via example
tofu plan                                   # dry-run
tofu apply                                  # deploy
```

The root module cannot be validated standalone (requires `us_east_1` provider alias
from a consumer). Always use `examples/simple` for validation instead.

No lint, test, or codegen commands — this is a pure module.

## Module structure

- `input.tf` — 7 variables: `bucket`, `hosted_zone`, `hostnames`, `tags`, `redirect_404_spa`, `create_iam_user`, `github_actions_deploy`
- `outputs.tf` — `deployer` (access key, sensitive) and `github_actions_role` (role ARN)
- `bucket.tf` — S3 bucket + website config + bucket policy (CloudFront OAC)
- `cloudfront.tf` — CloudFront distribution, OAC, CloudFront Function (redirect)
- `certificates.tf` — ACM cert (provider `aws.us_east_1`)
- `dns.tf` — Route53 zone lookup, validation records, A/AAAA alias records
- `iam_user.tf` — IAM user + access key + S3 write policy
- `github_actions.tf` — GitHub OIDC provider data, IAM role + trust policy + S3 write policy
- `redirect.js` — CloudFront Function (runtime `cloudfront-js-2.0`) that rewrites `/`-ending URIs to `index.html`

## Key quirks

- **ACM cert must use `aws.us_east_1` provider alias** (CloudFront requirement).
  Consumers must supply a separate `us-east-1` provider alias.
- `wait_for_deployment = false` on CloudFront — apply returns immediately.
- `price_class = "PriceClass_100"` (North America + Europe only).
- `redirect_404_spa` (default `false`): when `true`, 403 and 404 errors return
  `200` with `/index.html` body. Enable this for SPA client-side routing.
- `hostnames[0]` is used for cert domain; all entries are CloudFront aliases.
- `hosted_zone` must exist in Route53.
- CloudFront uses **Origin Access Control (OAC)** (not OAI).
- Deployer IAM user gets `s3:ListBucket` + `s3:*Object` — intended for CI/CD.
- `create_iam_user` (default `true`): toggle to skip the IAM user + access key.
- `github_actions_deploy` (default `null`): when set, creates an IAM role with OIDC trust
  for GitHub Actions. Expects the GitHub OIDC provider (`token.actions.githubusercontent.com`)
  to already exist in the account. The `sub` condition is open to all refs/environments
  when neither `allowed_branches` nor `allowed_environments` is specified.
  - `allowed_repos` — list of `"org/repo"` strings, e.g. `["my-org/my-site"]`
  - `allowed_branches` — optional, `"refs/heads/<pattern>"` with `*` wildcard support, e.g. `["refs/heads/main"]`
  - `allowed_environments` — optional, plain GitHub environment names, e.g. `["production", "staging"]`
- Deployer IAM user and GitHub Actions role can coexist or be toggled independently.
