import csv, glob
from collections import defaultdict

EC2_PRICING = {
    't2.micro': 0.0116, 't2.small': 0.023, 't2.medium': 0.0464, 't2.large': 0.0928,
    't3.nano': 0.0052, 't3.micro': 0.0104, 't3.small': 0.0208, 't3.medium': 0.0416,
    't3.large': 0.0832, 't3.xlarge': 0.1664, 't3.2xlarge': 0.3328,
    'm3.medium': 0.067, 'm3.large': 0.133, 'm3.xlarge': 0.266,
    'm5.large': 0.096, 'm5.xlarge': 0.192, 'm5.2xlarge': 0.384, 'm5.4xlarge': 0.768,
    'm7a.large': 0.1008, 'c3.xlarge': 0.210, 'c4.2xlarge': 0.398,
    'c5n.large': 0.108, 'c5n.2xlarge': 0.432, 'c6i.2xlarge': 0.34,
    'c7i-flex.8xlarge': 1.224, 'g5.xlarge': 1.006, 'g6e.4xlarge': 2.176,
}

RDS_PRICING = {
    'db.t3.micro': 0.017, 'db.t3.small': 0.034, 'db.t3.medium': 0.068,
    'db.t3.large': 0.136, 'db.t3.xlarge': 0.272,
    'db.t4g.micro': 0.016, 'db.t4g.small': 0.032, 'db.t4g.medium': 0.064, 'db.t4g.large': 0.128,
    'db.m5.large': 0.188, 'db.m5.xlarge': 0.376, 'db.m5.4xlarge': 1.504,
    'db.m6i.large': 0.192, 'db.m7g.xlarge': 0.364, 'db.r7g.2xlarge': 0.968,
    'db.serverless': 0.12,
}

# EC2 breakdown
ec2_by_type = defaultdict(int)
ec2_cost_by_type = defaultdict(float)
for f in glob.glob('SRSA_Compute/*-ec2.csv'):
    for row in csv.DictReader(open(f)):
        if row['state'] == 'running' and row['purchase_option'] == 'OnDemand':
            itype = row['instance_type']
            ec2_by_type[itype] += 1
            if itype in EC2_PRICING:
                ec2_cost_by_type[itype] += EC2_PRICING[itype]

print('=' * 80)
print('EC2 Cost Breakdown (Top 10):')
print('=' * 80)
sorted_ec2 = sorted(ec2_cost_by_type.items(), key=lambda x: x[1], reverse=True)
for itype, cost in sorted_ec2[:10]:
    count = ec2_by_type[itype]
    annual = cost * 8760
    print(f'{itype:20} {count:3}x @ ${EC2_PRICING[itype]:.4f}/hr = ${cost:6.2f}/hr (${annual:10,.2f}/year)')
print(f'\nTotal EC2 hourly: ${sum(ec2_cost_by_type.values()):.2f}')
print(f'Total EC2 annual: ${sum(ec2_cost_by_type.values()) * 8760:,.2f}')

# RDS breakdown
rds_by_type = defaultdict(int)
rds_cost_by_type = defaultdict(float)
multi_az_count = 0
for f in glob.glob('SRSA_RDS/*-rds.csv'):
    for row in csv.DictReader(open(f)):
        dbtype = row['db_instance_class']
        rds_by_type[dbtype] += 1
        if dbtype in RDS_PRICING:
            cost = RDS_PRICING[dbtype]
            if row['multi_az'] == 'Yes':
                cost *= 2
                multi_az_count += 1
            rds_cost_by_type[dbtype] += cost

print('\n' + '=' * 80)
print('RDS Cost Breakdown (Top 10):')
print('=' * 80)
sorted_rds = sorted(rds_cost_by_type.items(), key=lambda x: x[1], reverse=True)
for dbtype, cost in sorted_rds[:10]:
    count = rds_by_type[dbtype]
    annual = cost * 8760
    print(f'{dbtype:20} {count:3}x @ ${RDS_PRICING.get(dbtype, 0):.4f}/hr = ${cost:6.2f}/hr (${annual:10,.2f}/year)')
print(f'\nMulti-AZ instances: {multi_az_count}')
print(f'Total RDS hourly: ${sum(rds_cost_by_type.values()):.2f}')
print(f'Total RDS annual: ${sum(rds_cost_by_type.values()) * 8760:,.2f}')

print('\n' + '=' * 80)
print('COMPARISON:')
print('=' * 80)
print(f'EC2: 127 instances = ${sum(ec2_cost_by_type.values()) * 8760:,.2f}/year')
print(f'RDS: 141 instances = ${sum(rds_cost_by_type.values()) * 8760:,.2f}/year')
