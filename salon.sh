#! /bin/bash

echo "~~~~~ MY SALON ~~~~~"
echo
echo "Welcome to My Salon, how can I help you?"
echo

SERVICE_NAME=""
while [[ -z "$SERVICE_NAME" ]]; do
  psql --username=freecodecamp --dbname=salon --no-align --tuples-only --quiet \
    -c "SELECT service_id || ') ' || name FROM services ORDER BY service_id;"
  read SERVICE_ID_SELECTED

  SERVICE_NAME=$(psql --username=freecodecamp --dbname=salon --no-align --tuples-only --quiet \
    -v service_id="$SERVICE_ID_SELECTED" <<'SQL'
SELECT name FROM services WHERE service_id = :'service_id';
SQL
  )

  if [[ -z "$SERVICE_NAME" ]]; then
    echo
    echo "I could not find that service. What would you like today?"
  fi
done

echo
echo "What's your phone number?"
read CUSTOMER_PHONE

CUSTOMER_ID=$(psql --username=freecodecamp --dbname=salon --no-align --tuples-only --quiet \
  -v phone="$CUSTOMER_PHONE" <<'SQL'
SELECT customer_id FROM customers WHERE phone = :'phone';
SQL
)

if [[ -z "$CUSTOMER_ID" ]]; then
  echo
  echo "I don't have a record for that phone number, what's your name?"
  read CUSTOMER_NAME
  CUSTOMER_ID=$(psql --username=freecodecamp --dbname=salon --no-align --tuples-only --quiet \
    -v phone="$CUSTOMER_PHONE" \
    -v name="$CUSTOMER_NAME" <<'SQL'
INSERT INTO customers (phone, name) VALUES (:'phone', :'name') RETURNING customer_id;
SQL
  )
else
  CUSTOMER_NAME=$(psql --username=freecodecamp --dbname=salon --no-align --tuples-only --quiet \
    -v customer_id="$CUSTOMER_ID" \
    <<'SQL'
SELECT name FROM customers WHERE customer_id = :'customer_id';
SQL
  )
fi

echo
echo "What time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
read SERVICE_TIME

psql --username=freecodecamp --dbname=salon --no-align --tuples-only --quiet \
  -v customer_id="$CUSTOMER_ID" \
  -v service_id="$SERVICE_ID_SELECTED" \
  -v service_time="$SERVICE_TIME" <<'SQL' >/dev/null
INSERT INTO appointments (customer_id, service_id, time) VALUES (:'customer_id', :'service_id', :'service_time');
SQL

echo
echo "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."