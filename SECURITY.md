# Security Configuration Guide

## Securing Credentials in CloudHub

### Overview
Sensitive information like database passwords and API secrets should never be stored in plain text in configuration files. CloudHub provides secure properties that are encrypted at rest and in transit.

## CloudHub Secure Properties (Current Implementation)

### Secured Credentials
The following credentials are configured as secure properties in CloudHub:

- `db.password` - PostgreSQL database password
- `anypoint.platform.client_secret` - Anypoint Platform client secret

### Setup Instructions

#### 1. Access CloudHub Settings
1. Login to **Anypoint Platform**: https://anypoint.mulesoft.com
2. Navigate to **Runtime Manager**
3. Select your application: **file-processing-rds-api**
4. Click **Settings** tab

#### 2. Add Secure Properties
In the **Properties** section, add the following with **Hidden** checkbox enabled:

| Property Key | Property Value | Hidden |
|--------------|---------------|--------|
| `db.password` | `zAeRymF2S5` | ✅ Yes |
| `anypoint.platform.client_secret` | `08Bdeb638ADb4f1bB3810504BCd6d694` | ✅ Yes |

**Important**: Check the "Hidden" checkbox to encrypt the values

#### 3. Apply Changes
1. Click **Apply Changes** button
2. CloudHub will restart the application automatically (takes ~2 minutes)
3. Application will now use secure properties instead of config file values

### How It Works

#### In config-prod.yaml
```yaml
# Password NOT stored in file
db.password: # Retrieved from CloudHub secure properties
```

#### In file-processing-api.xml
```xml
<!-- Reference works the same way -->
<db:generic-connection password="${db.password}">
```

#### CloudHub Runtime
- Properties marked as "Hidden" are encrypted at rest
- Values are injected at runtime
- Not visible in logs or UI after saving
- Override any values from config files

### Verification

#### Check Application Logs
After deployment, verify secure properties are loaded:
```
[INFO] Successfully connected to database
[INFO] Application started
```

#### Test Database Connection
Upload a CSV file - if it processes successfully, secure properties are working.

## Additional Security Best Practices

### 1. Remove Hardcoded Credentials from Git
Ensure `config-prod.yaml` doesn't contain actual passwords before committing:

```yaml
# ✅ Good - Comment indicates where value comes from
db.password: # Set as secure property in CloudHub

# ❌ Bad - Never commit actual passwords
db.password: "zAeRymF2S5"
```

### 2. Use .gitignore
Add to `.gitignore` to prevent accidental commits:
```
*.yaml
*.properties
!application-types.xml
*-secret.txt
credentials.txt
```

### 3. Rotate Credentials Regularly
1. Update password in RDS database
2. Update `db.password` in CloudHub secure properties
3. Click "Apply Changes" - application restarts with new password

### 4. Separate Environments
Use different secure properties for DEV/TEST/PROD:

**Development Environment**
```
db.password=dev-password-here
```

**Production Environment**
```
db.password=prod-password-here
```

### 5. Limit Access
Control who can view/edit secure properties:
- Use CloudHub role-based access control (RBAC)
- Grant "Admin" role only to authorized users
- "Developer" role cannot view hidden properties

## Alternative Security Options

### Option 2: Mule Secure Configuration Properties

For more advanced encryption, use the Secure Configuration Properties module:

#### Add Dependency (pom.xml)
```xml
<dependency>
    <groupId>com.mulesoft.modules</groupId>
    <artifactId>mule-secure-configuration-property-module</artifactId>
    <version>1.2.5</version>
    <classifier>mule-plugin</classifier>
</dependency>
```

#### Create Encrypted Properties
```bash
# Use Mule encryption tool
java -cp mule-secure-configuration-property-module.jar \
  com.mulesoft.modules.secure.properties.SecurePropertiesEncryptor \
  encrypt "zAeRymF2S5" "mySecretKey"
```

#### Configure in XML
```xml
<secure-properties:config name="Secure_Properties" 
    file="secure.properties" 
    key="${encryption.key}">
</secure-properties:config>
```

**Pros**: Works locally and in CloudHub  
**Cons**: More complex setup, requires encryption key management

### Option 3: AWS Secrets Manager

For enterprise deployments using AWS infrastructure:

#### Add AWS Connector
```xml
<dependency>
    <groupId>com.mulesoft.connectors</groupId>
    <artifactId>mule-aws-secrets-manager-connector</artifactId>
    <version>1.0.0</version>
</dependency>
```

#### Retrieve from Secrets Manager
```xml
<aws-secrets-manager:config name="AWS_Config">
    <aws-secrets-manager:basic-connection 
        accessKey="${aws.access.key}" 
        secretKey="${aws.secret.key}"/>
</aws-secrets-manager:config>

<aws-secrets-manager:get-secret-value 
    secretId="rds-db-password"/>
```

**Pros**: Centralized secret management, audit logging, automatic rotation  
**Cons**: Additional AWS costs, more complex architecture

## Current Security Status

✅ **Implemented:**
- Database password secured via CloudHub properties
- API client secret secured via CloudHub properties
- Credentials removed from config-prod.yaml

⚠️ **Recommended Additional Steps:**
- Enable HTTPS for HTTP listener (currently HTTP only)
- Implement API authentication (OAuth 2.0 or API key)
- Add rate limiting to prevent abuse
- Enable CloudHub monitoring alerts

🔒 **Production Readiness:**
- Move to HTTPS listener with TLS certificates
- Implement OAuth 2.0 authentication
- Use dedicated load balancer with WAF
- Enable CloudHub VPN for RDS connection

## Troubleshooting

### Issue: Application Fails After Adding Secure Properties
**Cause**: Property name mismatch  
**Solution**: Ensure CloudHub property key exactly matches config reference:
- CloudHub: `db.password`
- XML: `${db.password}` (must match exactly)

### Issue: Cannot See Hidden Property Value
**Expected**: Hidden properties are encrypted and not visible after saving  
**Solution**: To verify, check application logs for connection success

### Issue: Database Connection Failed After Securing Password
**Cause**: Secure property not applied or wrong value  
**Solution**: 
1. Verify property is marked as "Hidden"
2. Click "Apply Changes" to restart
3. Check CloudHub logs for actual error

## Deployment Checklist

Before deploying with secure properties:

- [ ] Remove credentials from config-prod.yaml
- [ ] Add secure properties in CloudHub Settings
- [ ] Mark properties as "Hidden"
- [ ] Click "Apply Changes"
- [ ] Wait for restart (2-3 minutes)
- [ ] Test file upload to verify database connection
- [ ] Check CloudHub logs for errors
- [ ] Verify data stored in database

## Monitoring

### CloudHub Logs
Monitor for security-related issues:
```
[INFO] Database connection established
[ERROR] Database authentication failed - Check secure properties
```

### RDS Monitoring
Track failed login attempts in RDS logs to detect credential issues.

## Support

For security concerns:
- **MuleSoft Security Advisories**: https://help.mulesoft.com/s/security-advisories
- **CloudHub Security**: https://docs.mulesoft.com/runtime-manager/secure-application-properties
- **AWS RDS Security**: https://docs.aws.amazon.com/rds/

---

**Last Updated**: February 11, 2026  
**Security Level**: CloudHub Secure Properties (Standard)  
**Compliance**: Suitable for most production deployments
