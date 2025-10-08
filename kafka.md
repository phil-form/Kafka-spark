# 1 — Présentation générale

* **ZooKeeper** est un service de coordination distribué léger conçu pour fournir un espace de nommage synchronisé, des verrous légers, la gestion de configuration et l'élection de leader pour d'autres systèmes distribués. ([zookeeper.apache.org][1])
* **Kafka** est une plateforme de streaming distribuée (log distribué) pour transférer, stocker et traiter des flux d'événements à haute débits et faible latence. Les applications l'utilisent pour ingestion d’événements, pipelines, streaming et comme journal d’engagement durable. ([Apache Kafka][2])

---

# 2 — Pourquoi ces deux projets ? Cas d'usage

* Kafka fournit la **durabilité** et la **parallélisation** des flux d’événements (topics/partitions).
* ZooKeeper (historiquement) fournit la **coordination** / métadonnées nécessaires au fonctionnement interne (élection de contrôleur, stockage de certaines métadonnées et ACL, gestion de cluster). Aujourd'hui, Kafka évolue vers une architecture sans dépendance à ZooKeeper (KRaft). ([Apache Kafka][3])

---

# 3 — Apache ZooKeeper — concept & architecture

## Qu'est-ce que ZooKeeper ?

ZooKeeper est un service distribué qui expose une arborescence de nœuds nommés (**znodes**) accessibles via des opérations atomiques (get, set, create, delete). Il est conçu pour fournir coordination, cohérence et primitives distribuées (verrous, électeur, configuration partagée). ([zookeeper.apache.org][1])

## Modèle de données : znodes, éphèmeres, watchers

* **znodes** : noeuds de l’arbre, contiennent des octets et des métadonnées (stat).
* **Éphémères** : znodes créés en session qui disparaissent quand la session du client meurt — utile pour leader election et présence. ([zookeeper.apache.org][4])
* **Watchers** : mécanisme d’événement léger — un client peut “watcher” un znode et être notifié des changements (watch one-shot). Utilisé pour implémenter reconfiguration réactive et elections.

## Architecture d'ensemble

* **Ensemble (ensemble)** : collection de serveurs ZooKeeper. On exige un **quorum** (majorité) pour la progression (lecture/écriture en mode leader/follower). Pour tolérance de panne on déploie un nombre impair de nœuds (3, 5...). ([zookeeper.apache.org][1])
* **Leader / followers** : un leader gère les écritures et réplique aux followers ; l'élection du leader se fait via un protocole interne (séquence/éphémères sur /election). ([zookeeper.apache.org][5])

## Garanties & propriétés

* Lectures et écritures atomiques au niveau d’un znode.
* **FIFO** pour les requêtes de clients dans l’ordre per-session.
* Forte cohérence liée au quorum (consistence linéarisable pour écritures synchrones). ([zookeeper.apache.org][1])

## Opérations courantes & CLI

* `bin/zkCli.sh` — client CLI.
* Créer un znode : `create /path data`
* Lister : `ls /path` ; get/set/delete.
  Consultez la doc officielle pour recettes (leader election, locks, barriers). ([zookeeper.apache.org][5])

## Bonnes pratiques opérationnelles (ZooKeeper)

* Toujours 3 ou 5 nœuds en prod (nombre impair).
* S’assurer d’une faible latence réseau entre membres (ZK sensible à latence).
* Paramètres à vérifier : `tickTime`, `initLimit`, `syncLimit`, `dataDir` ; backups réguliers des snapshots et logs transactionnels.
* Sécuriser via ACLs, et restreindre accès au port client (2181) ; utiliser TLS/SASL pour authentification si nécessaire.

---

# 4 — Apache Kafka — concept & architecture

## Vue d’ensemble

Kafka est construit autour d’un **journal partitionné** (topic → partitions). Chaque partition est **ordonnée** et append-only. Les consommateurs lisent des offsets (entiers) pour consommer séquentiellement. ([Apache Kafka][2])

## Concepts clefs

* **Topic** : flux logique d’événements.
* **Partition** : shard d’un topic, stocke messages ordonnés avec offsets.
* **Broker** : serveur Kafka stockant partitions.
* **Leader / followers** : chaque partition a un leader (service des reads/writes) et des followers qui répliquent.
* **Offset** : position dans une partition (monotone).
* **ISR** (In-Sync Replicas) : liste des réplicas ayant rattrapé le leader.

## Réplication & disponibilité

* **replication.factor** (par topic) : nombre total de réplicas pour chaque partition ; production recommande 2 ou 3 (3 est un standard courant pour tolérance). **min.insync.replicas** (topic/broker) : nombre minimum de réplicas en ISR qui doivent ack avant qu’un `acks=all` retourne succès. Ensemble : `acks=all` + `min.insync.replicas>=2` → haute durabilité. ([docs.confluent.io][6])

## Producteurs (Producers)

* **acks** : `0`, `1`, `all(-1)` ; `all` (avec min.insync) garantit durabilité.
* **idempotence** (`enable.idempotence=true`) : empêche duplication lors de retries (génère ProducerId/PID et seqno). Nécessaire pour exactly-once producer guarantees.
* **batching** (`batch.size`, `linger.ms`) et **compression** (gzip/snappy/zstd) pour débit.
* **partitioner** : clé → partition (consistence clé→partition).

## Consommateurs (Consumers)

* **Consumer Group** : ensemble d’instances qui se partagent les partitions d’un topic ; chaque partition lue par au plus un consommateur dans le groupe.
* **Rééquilibrage** : quand un membre rejoint/quitte → réassignation des partitions. Les stratégies d’assignation (range, round-robin) existent.
* **Offsets** : les offsets committés servent de "bookmark". Les offsets committés sont enregistrés dans un topic interne `__consumer_offsets`. Cela permet reprise en cas de redémarrage ou rebalance. ([docs.confluent.io][7])

## Livraison et sémantiques

* **At-least-once** : comportement par défaut si producteurs réessaient et consommateurs committent *après* traitement — messages peuvent être traités deux fois.
* **At-most-once** : commit avant traitement (risque de perte).
* **Exactly-once** : Kafka offre une sémantique « exactly-once » pour les producteurs consommateurs via **idempotence** et **transactions** (transactional producer + isolation.level des consommateurs), à condition d’utiliser correctement les options (acks=all, idempotence, transactionalId, retries, max.in.flight.requests=1 côté client). Les transactions gèrent les commits atomiques dans les topics internes. ([docs.confluent.io][8])

## Logs, segments, rétention & compaction

* Chaque partition est persistée en segments de fichiers sur disque ; paramètres importants : `log.segment.bytes`, `log.retention.ms`, `log.cleanup.policy` (`delete` vs `compact`).
* **Compaction** conserve la dernière valeur par clé (utile pour topics de type "table").

## Outils CLI & Quickstart

* Quickstart officiel (start brokers, create topic, produce/consume) : voir guide officiel. Exemples : `kafka-topics.sh`, `kafka-console-producer.sh`, `kafka-console-consumer.sh`. ([Apache Kafka][9])

---

# 5 — Relation Kafka ↔ ZooKeeper — et KRaft (qu'est-ce qui change ?)

* **Historique** : Kafka utilisait ZooKeeper pour stocker et coordonner métadonnées (contrôleur, leader elections, ACL, topics meta) — ZooKeeper était donc requis en production.
* **Évolution (KRaft)** : Kafka a introduit un **quorum controller interne** (KRaft mode) qui remplace ZooKeeper, en intégrant la couche de contrôle metadata dans Kafka lui-même via Raft. Cela permet de supprimer la dépendance à ZooKeeper et d'unifier la stack. Des outils / processus de migration existent pour passer d’un cluster ZooKeeper-based vers KRaft. ([Apache Kafka][3])

> **Implication pratique** : si vous concevez une nouvelle installation, évaluez la version de Kafka et la maturité du mode KRaft (selon la version que vous comptez déployer) — KRaft simplifie l’opérationnel car il élimine la couche ZooKeeper, mais la migration d’un cluster en production peut nécessiter étapes planifiées. ([strimzi.io][10])

---

# 6 — Exemples rapides (commandes) — *mode classique avec ZooKeeper*

> **Dépendances** : chemins présumés `KAFKA_HOME/bin` ; remplacer versions/hosts selon installation.

1. **Démarrer ZooKeeper** (si vous utilisez ZooKeeper)

```bash
# depuis KAFKA_HOME (packaged zookeeper)
bin/zookeeper-server-start.sh config/zookeeper.properties
```

2. **Démarrer un broker Kafka**

```bash
bin/kafka-server-start.sh config/server.properties
```

3. **Créer un topic**

```bash
bin/kafka-topics.sh --create \
  --bootstrap-server localhost:9092 \
  --replication-factor 3 \
  --partitions 6 \
  --topic my-app-events
```

4. **Produire (console)**

```bash
bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic my-app-events
# tapez vos messages puis Ctrl+D
```

5. **Consommer (console, depuis début)**

```bash
bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 \
  --topic my-app-events --from-beginning
```

6. **Décrire un topic**

```bash
bin/kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic my-app-events
```

7. **Lister groupes & offsets**

```bash
bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list
bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group my-group --describe
```

> Pour un quickstart et détails exacts adaptés à votre version : consultez la doc officielle. ([Apache Kafka][9])

---

# 7 — Bonnes pratiques opérationnelles & tuning (règles générales)

* **HA & réplication** : ayez au moins 3 brokers et RF >= 2 (RF = 3 recommandé). `min.insync.replicas = 2` si vous voulez `acks=all` pour durabilité. ([docs.confluent.io][6])
* **Disques** : utiliser disques rapides (SSD), séparer logs Kafka sur disques dédiés (`log.dirs`).
* **Networking** : configurer `num.network.threads` / `num.io.threads` selon CPU/IO.
* **File descriptors** : augmenter limites (`ulimit -n`) pour la charge de nombreux partitions/fichiers.
* **Monitoring** : JMX metrics (broker, producer, consumer), exporter via Prometheus/Grafana, surveiller under-replicated partitions, consumer lag, GC, file descriptors.
* **Sécurité** : activer TLS (SSL) pour le transport, SASL (SCRAM/GSSAPI) pour l’authentification, ACLs côté Kafka ; sécuriser ZooKeeper si utilisé (ACLs ZK, SASL).
* **Backups & recovery** : Kafka est durable via réplicas mais prévoir plan de récupération, tester la restauration/sync après panne.

---

# 8 — Pièges fréquents & troubleshooting

* **ZooKeeper** : mauvaise taille d’ensemble (1 seul serveur en prod → risque), latence réseau entre membres → instabilité.
* **Under-replicated partitions (URP)** : signale brokers non synchronisés ; vérifier ISR et réseau/IO.
* **Unclean leader election** (`unclean.leader.election.enable=true`) : peut provoquer perte de données si activé — en prod désactivez-le si la durabilité est critique.
* **Consumer lag** : monitoring indispensable — lag élevé = consommateurs trop lents.
* **max.in.flight.requests > 1 + retries + idempotence=false** → risques de duplication ou désordre en cas d’erreurs. Pour exactly-once, respecter contraintes client. ([kafka.js.org][11])

---

# 9 — Références & lectures recommandées

(Principales sources officielles et articles de référence cités dans ce README)

* Apache Kafka — KRaft vs ZooKeeper (doc officiel). ([Apache Kafka][3])
* ZooKeeper Programmer's Guide (Apache ZooKeeper). ([zookeeper.apache.org][1])
* Kafka Documentation & Quickstart (Apache Kafka). ([Apache Kafka][9])
* Confluent — Conception des consumers & delivery semantics (offsets, exactly-once). ([docs.confluent.io][7])
* Best practices & production guidance (Confluent documentation — réplication/min.insync). ([docs.confluent.io][6])
* Guides & articles de migration KRaft (Strimzi / Confluent). ([strimzi.io][10])

---

## Remarques finales

* Si vous préparez un **nouveau** déploiement en 2025+, étudiez **KRaft** : il supprime la dépendance à ZooKeeper et simplifie l’exploitation (mais implique une migration planifiée pour clusters existants). Vérifiez la version de Kafka que vous comptez déployer et la maturité du mode KRaft pour cette version. ([Apache Kafka][3])

[1]: https://zookeeper.apache.org/doc/current/zookeeperProgrammers.html?utm_source=chatgpt.com "ZooKeeper Programmer's Guide - Apache ZooKeeper"
[2]: https://kafka.apache.org/documentation/?utm_source=chatgpt.com "Kafka 4.1 Documentation"
[3]: https://kafka.apache.org/41/documentation/zk2kraft.html?utm_source=chatgpt.com "Differences Between KRaft mode and ZooKeeper mode"
[4]: https://zookeeper.apache.org/doc/r3.7.2/zookeeperOver.html?utm_source=chatgpt.com "Because Coordinating Distributed Systems is a Zoo - ZooKeeper"
[5]: https://zookeeper.apache.org/doc/current/recipes.html?utm_source=chatgpt.com "ZooKeeper Recipes and Solutions"
[6]: https://docs.confluent.io/platform/current/kafka/post-deployment.html?utm_source=chatgpt.com "Best Practices for Kafka Production Deployments in ..."
[7]: https://docs.confluent.io/kafka/design/consumer-design.html?utm_source=chatgpt.com "Kafka Consumer Design"
[8]: https://docs.confluent.io/kafka/design/delivery-semantics.html?utm_source=chatgpt.com "Message Delivery Guarantees for Apache Kafka"
[9]: https://kafka.apache.org/quickstart?utm_source=chatgpt.com "Apache Kafka Quickstart"
[10]: https://strimzi.io/blog/2024/03/21/kraft-migration/?utm_source=chatgpt.com "From ZooKeeper to KRaft: How the Kafka migration works"
[11]: https://kafka.js.org/docs/transactions?utm_source=chatgpt.com "Transactions"
