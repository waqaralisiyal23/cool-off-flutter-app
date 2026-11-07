for E_DART_DEFINE in $(echo $DART_DEFINES | tr "," "\n")
do
    DC_DART_DEFINE=$(echo $E_DART_DEFINE | base64 --decode)
    KEY_VALUE=(${DC_DART_DEFINE//=/ })
    if [ ${KEY_VALUE[0]} == 'DART_ENV' ]
    then
      DART_ENV=${KEY_VALUE[1]}
    fi
done

if [ -z "$DART_ENV" ]
then
  DART_ENV="qa"
fi

# for config files
cp "${SRCROOT}/../config/${DART_ENV}.config" "${SRCROOT}/Flutter/GeneratedEnvironment.xcconfig"
