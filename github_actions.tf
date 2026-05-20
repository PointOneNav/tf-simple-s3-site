data "aws_iam_openid_connect_provider" "github" {
  count = var.github_actions_deploy != null ? 1 : 0
  url   = "https://token.actions.githubusercontent.com"
}

locals {
  gh_sub_branches = try(var.github_actions_deploy.allowed_branches, null)
  gh_sub_envs     = try(var.github_actions_deploy.allowed_environments, null)
  gh_sub_open     = local.gh_sub_branches == null && local.gh_sub_envs == null

  gh_sub_values = try(var.github_actions_deploy.allowed_repos, null) != null ? distinct(flatten([
    for repo in var.github_actions_deploy.allowed_repos : flatten([
      local.gh_sub_open
      ? ["repo:${repo}:*"]
      : concat(
        local.gh_sub_branches != null ? [for b in local.gh_sub_branches : "repo:${repo}:ref:${b}"] : [],
        local.gh_sub_envs != null ? [for e in local.gh_sub_envs : "repo:${repo}:environment:${e}"] : []
      )
    ])
  ])) : []
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  count = var.github_actions_deploy != null ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.gh_sub_values
    }
  }
}

resource "aws_iam_role" "github_actions" {
  count              = var.github_actions_deploy != null ? 1 : 0
  name               = "${var.bucket}-github-actions-deployer"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role[0].json
}

resource "aws_iam_role_policy" "github_actions_s3" {
  count  = var.github_actions_deploy != null ? 1 : 0
  policy = data.aws_iam_policy_document.deployer_s3_write.json
  role   = aws_iam_role.github_actions[0].name
}
