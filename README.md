# Set up AWS services

Collection de travaux pratiques pour apprendre à déployer et utiliser des services AWS de data engineering. Le dépôt rassemble des configurations Terraform, des scripts Python/PySpark, des requêtes SQL et des guides pas à pas.

Chaque dossier correspond à un atelier avec son propre README. Les ateliers se lancent séparément : il n'existe pas de déploiement Terraform global à la racine.

## Les ateliers

| Dossier | Objectif | Mise en œuvre |
| --- | --- | --- |
| [learn-terraform-get-started-aws](learn-terraform-get-started-aws/README.md) | Découvrir Terraform avec un bucket S3, son chiffrement et le blocage de l'accès public. | Terraform |
| [athena](athena/README.md) | Déposer des données sur S3 et les interroger en SQL avec Athena. | Terraform et SQL |
| [emr](emr/README.md) | Exécuter un traitement PySpark sur EMR et produire des fichiers Parquet sur S3. | Terraform, Python et shell |
| [glue](glue/README.md) | Configurer un job ETL Glue et son catalogue de données. | Terraform et PySpark |
| [lambda](lambda/README.md) | Construire une conversion CSV vers Parquet avec Lambda, S3 et Athena. | Terraform pour le bucket source, Python et étapes manuelles |
| [kinesis/kinesis-datastreams](kinesis/kinesis-datastreams/README.md) | Créer un flux, envoyer des événements et lire les enregistrements. | AWS CLI ou CloudShell |
| [lakeformation](lakeformation/README.md) | Appliquer des contrôles d'accès aux lignes et colonnes d'une table. | Console AWS |
| [quicksight](quicksight/README.md) | Préparer un data lake S3/Glue/Athena et créer des visualisations QuickSight. | Terraform et configuration QuickSight |
| [redshift](redshift/README.md) | Déployer Redshift Serverless avec un bucket S3 de staging. | Terraform |
| [stepfunctions](stepfunctions/README.md) | Orchestrer un cluster EMR avec Step Functions et EventBridge. | Terraform et définition de workflow |

## Prérequis

- Un compte AWS et des droits adaptés à l'atelier choisi.
- Git, Terraform et AWS CLI pour les ateliers qui les utilisent.
- Une session AWS configurée dans le terminal.
- Les données de démonstration nécessaires, préparées localement.

Les contraintes Terraform et les versions des providers varient selon les dossiers. Consultez les blocs `terraform` de l'atelier avant de l'initialiser ; certains demandent Terraform 1.10 ou supérieur.

## Démarrer un atelier Terraform

Clonez le dépôt et entrez dans l'atelier choisi, par exemple celui consacré à S3 :

```bash
git clone https://github.com/assabur/set-up-aws-services.git
cd set-up-aws-services/learn-terraform-get-started-aws
```

Vérifiez le compte AWS utilisé et les outils disponibles :

```bash
aws sts get-caller-identity
terraform version
```

Lisez le README de l'atelier, puis adaptez la région, les noms de buckets, les variables et les chemins de fichiers à votre environnement. Les noms de buckets S3 doivent être uniques globalement.

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

Examinez le plan avant de confirmer la création des ressources. Les opérations de chargement des données, les requêtes SQL et certaines configurations dans la console sont décrites dans chaque atelier.

Pour Glue, un exemple de variables est disponible :

```bash
cd ../glue
cp terraform.tfvars.example local.auto.tfvars
```

Adaptez ce fichier avant le déploiement. Les fichiers `*.auto.tfvars` sont ignorés par Git. Un fichier `terraform.tfvars` déjà présent est chargé automatiquement : vérifiez aussi son contenu et les éventuelles valeurs qui se recouvrent.

## Données et fichiers locaux

Les CSV et les fichiers de logs sont exclus de Git. Ils ne sont donc pas fournis après un clonage, même si les README des ateliers mentionnent des jeux d'exemple. Préparez des données synthétiques respectant les schémas décrits dans chaque guide.

Certains ateliers attendent notamment les chemins suivants :

| Atelier | Fichier local attendu |
| --- | --- |
| EMR | `emr/data/hr-salary-data.csv` |
| QuickSight | `quicksight/data/sales.csv`, ou le chemin défini par `csv_file_path` |
| Redshift | `redshift/data/sales_sample.csv` |
| Lake Formation | `lakeformation/data/orders.csv`, à charger manuellement |

Pour Athena, Glue et Lambda, suivez le guide de l'atelier pour les schémas, les emplacements S3 et le chargement des données.

L'atelier Step Functions référence `stepfunctions/scripts/salary_aggregations.py`, absent du dépôt. Avant de le déployer, fournissez ce script ou adaptez la référence ; l'atelier EMR contient un exemple dans `emr/scripts/salary_aggregations.py`.

Le `.gitignore` exclut également les états Terraform et le dossier `.terraform/`. Les fichiers `*.tfvars` ordinaires ne sont pas tous ignorés : utilisez un fichier `local.auto.tfvars` pour vos paramètres locaux et gardez les identifiants AWS hors des fichiers du projet.

## Nettoyer les ressources

Les services créés peuvent générer des frais, notamment EMR et Redshift. Après l'exercice, lancez depuis le dossier de l'atelier :

```bash
terraform plan -destroy
terraform destroy
```

La destruction peut supprimer les données des buckets selon la configuration. Sauvegardez ce que vous souhaitez conserver. Supprimez aussi les ressources créées manuellement en suivant le README de l'atelier : Terraform ne les gère pas automatiquement.
