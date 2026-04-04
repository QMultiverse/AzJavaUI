// infra/bicep/parameters/dev.bicepparam
// Development environment parameter values.
// Only values that differ from defaults are specified.

using '../main.bicep'

param env                = 'dev'
param location           = 'westeurope'
param corporateIpAddress = '103.214.46.138'   // Update to your IP