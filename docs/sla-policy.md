# SLA policy

GLPI calculates **priority** from **urgency** (how fast the requester needs it) and **impact** (how many people or how much of the business is affected). These are the targets I work against.

## Priority matrix (GLPI 11 default)

| Urgency \ Impact | Very low | Low | Medium | High | Very high |
|---|---|---|---|---|---|
| **Very high** | 2 Low | 3 Medium | 4 High | 5 Very high | 5 Very high |
| **High** | 2 Low | 3 Medium | 4 High | 4 High | 5 Very high |
| **Medium** | 2 Low | 2 Low | 3 Medium | 4 High | 4 High |
| **Low** | 1 Very low | 2 Low | 2 Low | 3 Medium | 3 Medium |
| **Very low** | 1 Very low | 1 Very low | 2 Low | 2 Low | 2 Low |

Priority 6 (Major) is never calculated; a technician sets it by hand for outages that stop the business.

## Targets (business hours, Mon-Fri 8:00-18:00)

| Priority | Example | First response | Resolution |
|---|---|---|---|
| 6 Major / 5 Very high | Whole team can't reach a business system | 15 min | 4 h |
| 4 High | One person can't work at all (lockout, no network, BitLocker) | 30 min | 8 h |
| 3 Medium | Something is broken but there's a workaround | 2 h | 2 business days |
| 2 Low / 1 Very low | Requests and minor issues (software install, second monitor) | 1 business day | 5 business days |

**Security tickets** (phishing clicks, lost MFA device) are handled as at least High, regardless of the calculated priority, because the risk grows with every minute.

## Setting this up in GLPI (optional)

Setup > SLM > Add: create a service level "Office hours", then add TTO (time to own) and TTR (time to resolve) entries matching the table above, and a ticket business rule that assigns them by priority. With that in place, GLPI shows SLA timers on every ticket and reports breaches in Assistance > Statistics.
