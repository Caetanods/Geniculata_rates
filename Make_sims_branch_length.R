## Here we perform simulations to show that the lack of informative branch lengths do not hinder our power to test relative rates of trait evolution.

## We simulate trees with a Birth-Death model, then simulate traits under a homogeneous BM model and test if we can detect relative rates of trait evolution even when the tree does not show meaninful branch lengths.

library(TreeSim)
library(geomorph)
library(parallel) ## Will use 4 cores for the simulations.
source("./functions/analysis.R")
source("./functions/prepare-data.R")

#####################################################
## Simulate trees:
tree <- sim.bd.taxa(13, numbsim=100, lambda=1.5, mu=0.5, complete=FALSE)

#####################################################
## Calculate mean shape data:
load("./data/Geniculata_data.RData")
male.gen <- colMeans( to.matrix(cord.gen.male) )
female.gen <- colMeans( to.matrix(cord.gen.female) )
male.scu <- colMeans( to.matrix(cord.scu.male) )
female.scu <- colMeans( to.matrix(cord.scu.female) )

#####################################################
## Simulate data under BM model. Doing first equal rates and then a relative rate similar to the one recovered from the empirical analysis (2x).
male.gen.sim.slow <- lapply(1:100, function(i) sapply(male.gen, function(x) sim.char(tree[[i]], par=0.5, model="BM", root=x) ) )
male.gen.sim.fast <- lapply(1:100, function(i) sapply(male.gen, function(x) sim.char(tree[[i]], par=1, model="BM", root=x) ) )
female.gen.sim <- lapply(1:100, function(i) sapply(female.gen, function(x) sim.char(tree[[i]], par=0.5, model="BM", root=x) ) )
for(i in 1:100) rownames(male.gen.sim.slow[[i]]) <- rownames(male.gen.sim.fast[[i]]) <- rownames(female.gen.sim[[i]]) <- tree[[1]]$tip.label

#####################################################
## Test rate of evolution of the genitalia.

## Test rates of evolution for the genitalia using the true (simulated) branch lengths.
equal.bd <- mclapply(1:100, function(i) compare.multi.evol.rates(A=cbind(male.gen.sim.slow[[i]], female.gen.sim[[i]]), gp=rep(c(1,2), each=40), phy=tree[[i]], Subset=FALSE), mc.cores=4)
diff.bd <- mclapply(1:100, function(i) compare.multi.evol.rates(A=cbind(male.gen.sim.fast[[i]], female.gen.sim[[i]]), gp=rep(c(1,2), each=40), phy=tree[[i]], Subset=FALSE), mc.cores=4)

## Repeat the analysis with the same simulated data and trees. Branch lengths all equal to 1.
unit.tree <- lapply(tree, function(x) compute.brlen(phy=x, method=rep(1, times=length(x$edge.length) ) ) )
equal.1 <- mclapply(1:100, function(i) compare.multi.evol.rates(A=cbind(male.gen.sim.slow[[i]], female.gen.sim[[i]]), gp=rep(c(1,2), each=40), phy=unit.tree[[i]], Subset=FALSE), mc.cores=4)
diff.1 <- mclapply(1:100, function(i) compare.multi.evol.rates(A=cbind(male.gen.sim.fast[[i]], female.gen.sim[[i]]), gp=rep(c(1,2), each=40), phy=unit.tree[[i]], Subset=FALSE), mc.cores=4)

## Repeat the analysis with the same simulated data and trees. Branch lengths generated by Grafen method.
grafen.tree <- lapply(tree, function(x) compute.brlen(phy=x, method="Grafen") )
equal.grafen <- mclapply(1:100, function(i) compare.multi.evol.rates(A=cbind(male.gen.sim.slow[[i]], female.gen.sim[[i]]), gp=rep(c(1,2), each=40), phy=grafen.tree[[i]], Subset=FALSE), mc.cores=4)
diff.grafen <- mclapply(1:100, function(i) compare.multi.evol.rates(A=cbind(male.gen.sim.fast[[i]], female.gen.sim[[i]]), gp=rep(c(1,2), each=40), phy=grafen.tree[[i]], Subset=FALSE), mc.cores=4)

#####################################################
## Results:
res.equal.bd <- t( sapply(equal.bd, function(x) c(x$sigma.d.ratio, x$P.value) ) )
res.diff.bd <- t( sapply(diff.bd, function(x) c(x$sigma.d.ratio, x$P.value) ) )
res.equal.1 <- t( sapply(equal.1, function(x) c(x$sigma.d.ratio, x$P.value) ) )
res.diff.1 <- t( sapply(diff.1, function(x) c(x$sigma.d.ratio, x$P.value) ) )
res.equal.grafen <- t( sapply(equal.grafen, function(x) c(x$sigma.d.ratio, x$P.value) ) )
res.diff.grafen <- t( sapply(diff.grafen, function(x) c(x$sigma.d.ratio, x$P.value) ) )

## pdf("Trait_rate_branch_length_sims.pdf")
## par(mfrow = c(2,2))
## boxplot(res.equal.bd[,1], res.equal.1[,1], res.equal.grafen[,1], ylim=c(1,4), names=c("Birth-Death", "Unit tree", "Grafen"), main="Rate ratio")
## abline(h=1, col="red", lty=3, lwd=2)
## boxplot(res.equal.bd[,2], res.equal.1[,2], res.equal.grafen[,2], names=c("Birth-Death", "Unit tree", "Grafen"), main="P value")
## abline(h=0.05, col="red", lty=3, lwd=2)
## boxplot(res.diff.bd[,1], res.diff.1[,1], res.diff.grafen[,1], ylim=c(1,4), names=c("Birth-Death", "Unit tree", "Grafen"), main="Rate ratio")
## abline(h=2, col="red", lty=3, lwd=2)
## boxplot(res.diff.bd[,2], res.diff.1[,2], res.diff.grafen[,2], names=c("Birth-Death", "Unit tree", "Grafen"), main="P value")
## abline(h=0.05, col="red", lty=3, lwd=2)
## dev.off()

pdf("sigma_branch_lengths.pdf", width = 8, height = 11)
par(mfrow = c(2,1))
boxplot(res.equal.bd[,1], res.equal.1[,1], res.equal.grafen[,1], res.diff.bd[,1], res.diff.1[,1], res.diff.grafen[,1], ylim=c(1,4), names=c("Birth-Death", "Unit tree", "Grafen", "Birth-Death", "Unit tree", "Grafen"), notch=TRUE, col=rep(c("white","gray"),each=3) )
segments(0.5, 1, 3.5, 1, col="red", lty=2, lwd=2)
segments(3.5, 2, 6.5, 2, col="red", lty=2, lwd=2)
boxplot(res.equal.bd[,2], res.equal.1[,2], res.equal.grafen[,2], res.diff.bd[,2], res.diff.1[,2], res.diff.grafen[,2], names=c("Birth-Death", "Unit tree", "Grafen", "Birth-Death", "Unit tree", "Grafen"), notch=TRUE, col=rep(c("white","gray"),each=3) )
segments(0.5, 0.05, 6.5, 0.05, col="red", lty=2, lwd=2)
dev.off()

abs.equal.bd <- t( sapply(equal.bd, function(x) x$sigma.d.gp ) )
abs.diff.bd <- t( sapply(diff.bd, function(x) x$sigma.d.gp ) )
abs.equal.1 <- t( sapply(equal.1, function(x) x$sigma.d.gp ) )
abs.diff.1 <- t( sapply(diff.1, function(x) x$sigma.d.gp ) )
abs.equal.grafen <- t( sapply(equal.grafen, function(x) x$sigma.d.gp ) )
abs.diff.grafen <- t( sapply(diff.grafen, function(x) x$sigma.d.gp ) )

## We can see, based on the histograms, that the absolute value of the rates do vary in function of the branch lengths, however, the ratio of the BM rates for two traits will not.
hist(abs.equal.bd[,1], breaks = 100)
hist(abs.equal.1[,1], breaks = 100)
hist(abs.equal.grafen[,1], breaks = 100)
