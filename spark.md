# 1 — Présentation générale

**Apache Spark** est un moteur de calcul distribué open-source conçu pour traiter de grands volumes de données à haute vitesse.
Il permet le calcul **en mémoire (in-memory)**, l’exécution **parallèle** sur clusters, et fournit une API unifiée pour le traitement **batch** et **streaming**.

Spark a été développé à l’origine à l’Université de Californie, Berkeley (AMP Lab) et est aujourd’hui un projet majeur de la fondation Apache.

---

# 2 — Objectifs et cas d’usage

Spark vise à surmonter les limites de Hadoop MapReduce en offrant :

* Une **vitesse de traitement** supérieure grâce au calcul en mémoire (RDD).
* Une **API expressive** (Scala, Python, Java, R, SQL).
* Une **intégration native** de modules : SQL, ML, graphes, streaming.
* Une **scalabilité horizontale** sur des clusters de milliers de nœuds.

**Cas d’usage typiques** :

* Traitement ETL massivement parallèle.
* Analyse de logs et données IoT.
* Apprentissage automatique (MLlib).
* Streaming temps réel (Structured Streaming).
* Requêtes analytiques ad-hoc via Spark SQL.

---

# 3 — Architecture et composants principaux

Spark est construit autour de **Spark Core**, qui fournit les primitives de calcul distribuées, et de plusieurs bibliothèques haut-niveau :

| Module                                     | Description                                      |
| ------------------------------------------ | ------------------------------------------------ |
| **Spark Core**                             | Gestion du cluster, exécution, résilience, RDD.  |
| **Spark SQL**                              | Requêtes SQL, DataFrames, intégration JDBC/Hive. |
| **Spark Streaming / Structured Streaming** | Traitement de flux en quasi temps réel.          |
| **MLlib**                                  | Bibliothèque de Machine Learning distribuée.     |
| **GraphX**                                 | Traitement et calcul de graphes distribués.      |

---

# 4 — Modèle de programmation

### 4.1 RDD — Resilient Distributed Dataset

L’unité fondamentale de données dans Spark.
Un RDD est :

* **Immuable** (non modifiable après création).
* **Distribué** (partitionné sur plusieurs nœuds).
* **Résilient** (recréé automatiquement à partir du DAG en cas de panne).

Deux types d’opérations :

* **Transformations** (lazy : `map`, `filter`, `flatMap`, `reduceByKey`…)
* **Actions** (évaluées : `collect`, `count`, `saveAsTextFile`…)

### 4.2 DataFrame

Abstraction de plus haut niveau : table structurée (colonnes typées).
Permet : planification optimisée via **Catalyst Optimizer**, compatibilité SQL.

### 4.3 Dataset

Combinaison du typage fort (Scala/Java) et des optimisations du DataFrame.

---

# 5 — Exécution distribuée

Chaque application Spark se compose de :

* **Driver Program** : point d’entrée (contient le code utilisateur, crée le SparkContext, génère le DAG d’exécution).
* **Cluster Manager** : orchestre l’allocation des ressources (Standalone, YARN, Mesos, Kubernetes).
* **Executors** : processus sur les nœuds travailleurs exécutant les tâches.

Flux général :

1. Le Driver soumet un job (DAG).
2. Le Cluster Manager alloue des ressources.
3. Les Executors exécutent les tasks et renvoient les résultats au Driver.

---

# 6 — Modes de déploiement

| Mode           | Description                                                             |
| -------------- | ----------------------------------------------------------------------- |
| **Local**      | Débogage sur machine locale.                                            |
| **Standalone** | Gestion de cluster intégrée à Spark.                                    |
| **YARN**       | Intégration Hadoop (YARN Resource Manager).                             |
| **Mesos**      | Gestion fine des ressources sur plusieurs frameworks.                   |
| **Kubernetes** | Déploiement moderne : pods Spark Driver + Executors orchestrés par K8s. |

---

# 7 — DAG, stages et tasks

Spark décompose les transformations en un **DAG** (Directed Acyclic Graph).
Le DAG est divisé en **stages**, eux-mêmes découpés en **tasks** (une par partition).

* Les **narrow transformations** (map, filter) peuvent s’exécuter localement.
* Les **wide transformations** (groupBy, reduceByKey) nécessitent un **shuffle** (échange de données entre nœuds).

Spark optimise le plan d’exécution pour réduire les shuffles.

---

# 8 — Tolérance aux pannes et mémoire

* Les RDD conservent la trace de leurs transformations (linéage). En cas de perte d’une partition, Spark la **recalcule**.
* Mécanismes de **checkpointing** et **persistency** (`cache`, `persist`) pour éviter recalculs coûteux.
* Gestion mémoire unifiée : fraction allouée à exécution (shuffle, aggregations) et à stockage (cache).
* Garbage Collection : tuning via `spark.memory.fraction`, `spark.memory.storageFraction`.

---

# 9 — API principales

* **Spark Core** : API RDD (Scala, Java, Python, R).
* **Spark SQL** : `spark.sql("SELECT ...")`, DataFrames, intégration JDBC/Hive.
* **Spark Streaming** (legacy) et **Structured Streaming** (API unifiée, DataFrames).
* **MLlib** : pipelines ML (classification, clustering, régression, recommandation).
* **GraphX** : graphes, PageRank, shortest path.

---

# 10 — Spark SQL et Catalyst Optimizer

* **Catalyst Optimizer** transforme le plan logique en plan physique optimal.
* Support des **UDF** (User Defined Functions).
* **Tungsten Engine** : génération de bytecode pour exécution en mémoire et vectorisée.

---

# 11 — Spark Streaming et Structured Streaming

### Spark Streaming (legacy)

* Fonctionne par micro-batchs fixes (ex. 1 seconde).
* API DStream (désormais remplacée).

### Structured Streaming

* API moderne unifiée avec Spark SQL.
* Fonctionne en micro-batch ou en mode continu (continuous processing).
* Sources : Kafka, socket, fichiers, Delta Lake…
* Garanties : *at-least-once* (par défaut) ou *exactly-once* via checkpoint + idempotence.

---

# 12 — Bonnes pratiques de performance et tuning

* **Partitionnement** : ajuster nombre de partitions (`repartition`, `coalesce`).
* **Broadcast joins** : petits jeux de données broadcastés pour éviter les shuffles.
* **Cache intelligemment** les DataFrames réutilisés.
* **Éviter collect()** sur de gros datasets (ramène tout au driver).
* **Utiliser Spark SQL** : l’optimiseur Catalyst produit des plans plus efficaces.
* **Surveiller le GC** : taille des partitions et objets Python/Java trop gros → out-of-memory.
* **Configurer executors** : `--executor-memory`, `--executor-cores`, `--num-executors`.

---

# 13 — Sécurité, monitoring et administration

* **Authentification** : Kerberos, OAuth, ou intégration Hadoop YARN.
* **Chiffrement** : TLS entre nodes et chiffrement au repos (fs-level).
* **ACLs** : contrôle accès REST API et UI Web.
* **Monitoring** : Spark UI (`http://driver:4040`), metrics via Dropwizard, export Prometheus.
* **Logs** : stockés par executor ; peuvent être envoyés vers HDFS ou système de logs centralisé.

---

# 14 — Exemples rapides

### Exemple 1 : exécution locale

```bash
./bin/spark-shell --master local[4]
```

```scala
val data = sc.parallelize(1 to 10)
val result = data.map(_ * 2).reduce(_ + _)
println(result)
```

### Exemple 2 : exécution cluster (Standalone)

```bash
./bin/spark-submit \
  --master spark://master:7077 \
  --deploy-mode cluster \
  --class org.example.MyJob \
  myjob.jar arg1 arg2
```

### Exemple 3 : SQL

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("Demo").getOrCreate()
df = spark.read.csv("data.csv", header=True, inferSchema=True)
df.groupBy("category").count().show()
```

---

# 15 — Pièges fréquents et diagnostic

| Problème              | Cause fréquente                          | Solution                                                      |
| --------------------- | ---------------------------------------- | ------------------------------------------------------------- |
| **OutOfMemoryError**  | partitions trop grandes ou collect()     | augmenter mémoire / partitionner davantage                    |
| **Shuffle trop lent** | réseau ou clé de partition déséquilibrée | utiliser partitionnement explicite                            |
| **Skew data**         | clés hot-spot (ex : "null")              | salage des clés (key + random salt)                           |
| **Driver bloqué**     | trop de résultats collectés              | utiliser actions partielles ou écrire vers stockage distribué |
| **PySpark lent**      | sérialisation Python–JVM                 | activer Arrow (`spark.sql.execution.arrow.enabled=true`)      |

---

# 16 — Références et lectures recommandées

* [Documentation officielle Apache Spark](https://spark.apache.org/docs/latest/)
* [Structured Streaming Programming Guide](https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html)
* [Spark SQL, DataFrames and Datasets Guide](https://spark.apache.org/docs/latest/sql-programming-guide.html)
* [Tuning Guide](https://spark.apache.org/docs/latest/tuning.html)
* [Monitoring & Instrumentation Guide](https://spark.apache.org/docs/latest/monitoring.html)
* [MLlib Guide](https://spark.apache.org/docs/latest/ml-guide.html)

---

## Remarques finales

* Spark est conçu pour être **modulaire** et **évolutif** : le même code peut s’exécuter localement, sur un cluster Hadoop YARN, ou Kubernetes.
* Si tu construis de nouveaux pipelines aujourd’hui, privilégie **Structured Streaming** plutôt que Spark Streaming ; et **DataFrame/Dataset API** plutôt que RDD API.
* Pour la performance : réduire les shuffles, préférer les opérations SQL, et surveiller la mémoire des executors.
