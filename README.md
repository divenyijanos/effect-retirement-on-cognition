The effect of retirement on cognitive performance
==================================================

Repo for my paper on the effect of retirement on cognitive performance

The shell script `run.sh` takes one argument, the path to the folder which contains the original SHARE data (downloadable under certain conditions from [this webpage](http://www.share-project.org/)), and executes all of the scripts which generate the exhibits of the paper:
* `merge.do` - used to merge different parts of different waves of SHARE
* `derive_clean.do` - put together the data of merged waves for analysis (create some useful new variables)
* `replication_MP.do` - replicate and put into context the results of Mazzonna-Perachi (2012)
* `replication_B.do` - replicate and put into context the results of Bonsang et al. (2012)
* `panel_regressions.do` - do the panel analysis (differences)
* `panel_graphs.do` - create graphs on panel
* `cs_graphs.do` - create cross-sectional graphs (only included in presentation)
