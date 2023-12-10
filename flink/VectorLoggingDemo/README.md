## Using a combination of Vector.dev (a logging agent), Azure HDInsight Kafka and Azure HDInsight Flink on AKS can provide a hugely cost effective and powerful logging solution worth looking at the following diagram:

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/f0ce02d0-1293-427c-916d-500aa4e3a833)


Logs coming from a source to Azure HDInsight Kafka.  Flink reads the data from Azure HDInsight Kafka and allows you to run queries on the data and then the data back to ADLSgen2 in a format suitable for long time storage and querying.![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/d3b242d0-5cbe-4b1e-ac92-3e8b838a10a5)


## Vector(logging agent)

Vector is a high-performance observability data pipeline that enables you to collect, transform, and route all of your logs and metrics.![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/564e8370-57f8-4a3d-b231-8c1c501d6daf)
In this blog, we will use vector.dev as a logging agent that can submit logs to a Kafka cluster.

#Ref<br>
https://vector.dev/docs/setup/quickstart/

Install Vector on Kafka VM directly:

```
root@hn0-kafkad:/home/sshuser# curl --proto '=https' --tlsv1.2 -sSfL https://sh.vector.dev | bash
                                   __   __  __
                                   \ \ / / / /
                                    \ V / / /
                                     \_/  \/

                                   V E C T O R
                                    Installer


--------------------------------------------------------------------------------
Website: https://vector.dev
Docs: https://vector.dev/docs/
Community: https://vector.dev/community/
--------------------------------------------------------------------------------

>>> We'll be installing Vector via a pre-built archive at https://packages.timber.io/vector/0.34.0/
>>> Ready to proceed? (y/n)

>>> y

--------------------------------------------------------------------------------

>>> Downloading Vector via https://packages.timber.io/vector/0.34.0/vector-0.34.0-x86_64-unknown-linux-gnu.tar.gz ✓
>>> Unpacking archive to /root/.vector ... ✓
>>> Adding Vector path to /root/.zprofile ✓
>>> Adding Vector path to /root/.profile ✓
>>> Install succeeded! 🚀
>>> To start Vector:

    vector --config /root/.vector/config/vector.yaml

>>> More information at https://vector.dev/docs/
```


Once Vector is installed, let’s check to make sure that it’s working correctly:

```
root@hn0-kafkad:/home/sshuser# vector --version

Command 'vector' not found, did you mean:

  command 'victor' from deb spark

Try: apt install <deb name>

root@hn0-kafkad:/home/sshuser# echo $PATH
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
root@hn0-kafkad:/home/sshuser# export PATH=$PATH:/root/.vector/bin
root@hn0-kafkad:/home/sshuser# source ~/.bashrc
root@hn0-kafkad:/home/sshuser# vector --version
vector 0.34.0 (x86_64-unknown-linux-gnu c909b66 2023-11-07 15:07:26.748571656)
```


