# Requirement 

- Install docker

# Build command

```sh
docker-compose up -d --build
docker exec -it instagram_chatbot_api bundle exec rails db:migrate
```

# Import sample data to database

- Download `instagram_chatbot_api.sql`
- Import to database by command

```sh
docker cp ~/Downloads/instagram_chatbot.sql instagram_chatbot_db:/instagram_chatbot.sql
docker exec -it instagram_chatbot_db bash
mysql instagram_chatbot < /instagram_chatbot.sql
```