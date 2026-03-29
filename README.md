# 🚀 Canary Deployment CI/CD Pipeline

A production-ready GitHub Actions workflow for automated deployments to AWS EC2 with **canary deployment strategy**, security scanning, and Slack notifications.

## ✨ Features

- **Multi-environment Support** - Deploys to Dev, Staging, and Production environments
- **Canary Deployment** - Safely test new versions with a subset of traffic
- **Automated Security Scanning** - Trivy vulnerability scanning on every build
- **Traffic Weight Management** - Gradual rollout from 10% → 100%
- **Health Monitoring** - Background monitoring during canary phase
- **Rollback Capability** - One-click rollback to stable version
- **Slack Integration** - Real-time notifications for deployments, promotions, and rollbacks

## 🏗️ Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   GitHub Push    │────▶│  Build & Scan   │────▶│  Deploy Jobs    │
│   (main/dev)    │     │  (Docker + Trivy)│     │  (EC2)          │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                    ┌───────────────────────────────────┤
                    ▼                                   ▼
            ┌───────────────┐                   ┌───────────────┐
            │ canary-deploy │                   │    deploy     │
            │  (port 3003)  │                   │  (port 3000)  │
            └───────────────┘                   └───────────────┘
                    │                                   │
                    ▼                                   ▼
            ┌───────────────┐                   ┌───────────────┐
            │   10% traffic │                   │   90% traffic │
            └───────────────┘                   └───────────────┘
                    │                                   │
                    └─────────────┬─────────────────────┘
                                  ▼
                          ┌───────────────┐
                          │     Nginx     │
                          │   (Load Bal)  │
                          └───────────────┘
                                  │
                                  ▼
                          ┌───────────────┐
                          │    Users      │
                          └───────────────┘
```

## 📁 Project Structure

```
.
├── .github/workflows/
│   └── deploy.yml          # GitHub Actions CI/CD pipeline
├── nginx/
│   ├── prod.conf           # Production nginx config with upstream
│   ├── staging.conf        # Staging nginx config
│   └── dev.conf            # Dev nginx config
├── scripts/
│   ├── deploy.sh           # Reusable deployment script
│   ├── monitor-canary.sh    # Canary health monitoring
│   └── update-canary-weight.sh  # Traffic weight adjustments
├── terraform/
│   ├── main.tf             # Terraform configuration
│   └── modules/            # Reusable Terraform modules
└── src/
    └── server.js           # Node.js application
```

## 🔄 Deployment Flow

### 1. Push to Branch
```bash
git push origin main      # Triggers canary deployment to production
git push origin staging   # Triggers standard deployment to staging
git push origin dev       # Triggers standard deployment to dev
```

### 2. Pipeline Stages
1. **Build & Push** - Docker image built and pushed to ECR
2. **Security Scan** - Trivy scans for CRITICAL/HIGH vulnerabilities
3. **Deploy** - Container deployed to EC2 via SSH
4. **Health Check** - Verifies application is responding
5. **Notify** - Slack notification sent with deployment status

### 3. Canary Flow (main branch)
```
Deploy canary → Monitor health → Increase traffic → Promote OR Rollback
     ↓              ↓               ↓                ↓
  10% traffic    10-30 min      25% → 50% → 100%   Switch traffic
```

## 🎮 Manual Triggers

### Promote Canary
```bash
curl -X POST https://api.github.com/repos/{owner}/{repo}/dispatches \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -d '{"event_type": "promote-canary"}'
```

### Rollback
```bash
curl -X POST https://api.github.com/repos/{owner}/{repo}/dispatches \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -d '{"event_type": "rollback"}'
```

## ⚙️ Configuration

### Required Secrets
| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY` | AWS access key ID |
| `AWS_SECRET_KEY` | AWS secret access key |
| `EC2_SSH_KEY` | Private SSH key for EC2 access |
| `EC2_IP` | EC2 instance IP address |
| `SLACK_WEBHOOK` | Slack webhook URL for notifications |

### Environment Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `AWS_REGION` | AWS region | `ap-south-1` |
| `ECR_REGISTRY` | ECR registry URL | (configured) |
| `ECR_REPO` | ECR repository name | `devops-app-repo` |

## 🔒 Security

- **Trivy Scanning** - Scans Docker images for vulnerabilities
- **IAM Roles** - Uses EC2 IAM role for ECR authentication
- **SSH Key** - Secrets stored in GitHub Actions encrypted
- **Environment Variables** - Sensitive data never exposed in logs

## 📊 Monitoring

### View Logs
```bash
# SSH into EC2 and check monitoring logs
ssh -i key.pem ubuntu@<ec2-ip>
tail -f /home/ubuntu/canary-monitor.log
```

### Check Container Status
```bash
docker ps
docker logs <container-name>
```

## 🤝 Contributing

1. Create a feature branch (`git checkout -b feature/amazing`)
2. Commit changes (`git commit -m 'Add amazing feature'`)
3. Push to branch (`git push origin feature/amazing`)
4. Open a Pull Request

## 📝 License

MIT License - See LICENSE file for details

---

Built with ❤️ using GitHub Actions, AWS EC2, Docker, and Terraform
