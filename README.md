# aws-prestashop

## Running locally

Start the containers with
```bash
docker-compose --env-file env/.env.dev up
```

OR one by one since I removed the healthcheck (while debugging on AWS, couldn't reach the logs)
```bash
docker-compose --env-file env/.env.dev up db_ps -d && sleep 15 && docker-compose --env-file env/.env.dev up prestashop
```