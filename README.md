# sm_scan (Secrets Manager scan)

A POSIX-compliant tool to easily retrieve secrets from IBM Secrets Manager.

In order to get a secret's data, IBM Secrets Manager first requires anybody to first get the secret ID (which has a UUID format and is very hard to remember).

It would be much more user-friendly to request the secret name (which the user sets and can be easy to remember) in order to get the secret data.

This tool does exactly that. You simply provide the secret name (and authentication values) and you get its secret data back.

The tool was designed to have as little dependencies as possible with the aim of making it faster, reliable, compatible, secure and having the smallest footprint possible.

Pull Requests are welcome. If you want to contribute, take a look at [CONTRIBUTING.md](CONTRIBUTING.md)

Open an issue to report bugs or to suggest enhancements.

## Usage

The easiest way to use this tool is to pull the image from Dockerhub and provide the required values as environment variables.

The required environment variables are the following:
- **secret_name**
- **secret_type** (Defaults to `kv` if not provided)
- **service_url**
- **api_key**

Basic usage:
```bash
podman run --rm \
-e api_key="<API_KEY>" \
-e secret_name="<Secret_name>" \
-e service_url="<Service_URL>" \
alanverdugo/sm_scan:v1
```

If the provided values are correct and the API key has the correct permissions, an output similar to this should be shown:

```bash
Secret name:
<secret_name>
Secret payload:
{
  "a_secret_key": "a_secret_value"
}
```

Of course, you can also download this repository contents and build the image locally.

### Examples

Note: The following are fictitious examples, don't get excited.

```bash
podman run --rm \
-e api_key="s0m3_fak3_v4lu3" \
-e secret_name="development.dbs.postgres" \
-e service_url="https://7119.us-south.secrets-manager.appdomain.cloud" \
alanverdugo/sm_scan:v1
```

Output:

```bash
Secret name:
development.dbs.postgres
Secret payload:
{
  "username": "AzureDiamond",
  "password": "hunter2"
}
```

Since a search param is used while looking for the secrets names, depending on the structure and naming of your secrets, this tool could be used to search for secrets "recursively".

For example, if you have secrets named:
- development.dbs.postgres
- development.dbs.mongodb
- development.dbs.mysql

...and use this tool to search for `development.dbs`, you would get the secret payload for all 3 secrets listed above. This is very useful for system administrators, or to quickly get many values with just one command.

Example:
```bash
podman run --rm \
-e api_key="s0m3_fak3_v4lu3" \
-e secret_name="development.dbs" \
-e service_url="https://7119.us-south.secrets-manager.appdomain.cloud" \
alanverdugo/sm_scan:v1
```

Output:

```bash
Secret name:
development.dbs.postgres
Secret payload:
{
  "username": "AzureDiamond",
  "password": "hunter2"
}
Secret name:
development.dbs.mongodb
Secret payload:
{
  "username": "Gandalf",
  "password": "Mellon"
}
Secret name:
development.dbs.mysql
Secret payload:
{
  "username": "Ozymandias",
  "password": "RamesesII"
}
```
