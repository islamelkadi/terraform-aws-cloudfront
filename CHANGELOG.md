## [1.0.2](https://github.com/islamelkadi/terraform-aws-cloudfront/compare/v1.0.1...v1.0.2) (2026-03-08)


### Bug Fixes

* add CKV_TF_1 suppression for external module metadata ([fd57800](https://github.com/islamelkadi/terraform-aws-cloudfront/commit/fd5780060532f17fb80c24df8c667e9c68c5dc3f))
* add skip-path for .external_modules in Checkov config ([45aa64b](https://github.com/islamelkadi/terraform-aws-cloudfront/commit/45aa64b5bb73dd841da0094b3d12a22e17fcfcda))
* address Checkov security findings ([e97bced](https://github.com/islamelkadi/terraform-aws-cloudfront/commit/e97bcedc1f13a756d6aecf294020bfe4ada54a65))
* correct .checkov.yaml format to use simple list instead of id/comment dict ([f317e9c](https://github.com/islamelkadi/terraform-aws-cloudfront/commit/f317e9c1362512955bf86368d9626d0eabe9f611))
* remove skip-path from .checkov.yaml, rely on workflow-level skip_path ([feda075](https://github.com/islamelkadi/terraform-aws-cloudfront/commit/feda075b56aabd8675f7d97e39c6158560cd7656))
* update workflow path reference to terraform-security.yaml ([2222ff0](https://github.com/islamelkadi/terraform-aws-cloudfront/commit/2222ff0cef1516fbc1e65b4ed2984dcc344ec598))

## [1.0.1](https://github.com/islamelkadi/terraform-aws-cloudfront/compare/v1.0.0...v1.0.1) (2026-03-08)


### Code Refactoring

* enhance examples with real infrastructure and improve code quality ([932b111](https://github.com/islamelkadi/terraform-aws-cloudfront/commit/932b1118e872374816225b87d2f0c09b295e2b7d))

## 1.0.0 (2026-03-07)


### ⚠ BREAKING CHANGES

* First publish - CloudFront Terraform module

### Features

* First publish - CloudFront Terraform module ([fd9123d](https://github.com/islamelkadi/terraform-aws-cloudfront/commit/fd9123dc433283e8585092281f712f12ed400e34))
