# code-samples

## `penguin_lr_pca.ipynb` Classification with Logistic Regression and PCA, Python, Fall 2021 ([code](https://github.com/franklinshe/code-samples/blob/master/penguin_lr_pca.ipynb))

In my Machine Learning class, I conducted an analysis of penguin species using logistic regression and Principal Component Analysis (PCA) with data from Dr. Kristen Gorman and the Palmer Station, Antarctica LTER. The project involved data preprocessing, visualization, and model training. I assessed the logistic regression model's performance with various features and training sizes, then applied PCA to reduce dimensionality and visualize decision boundaries. This approach provided valuable insights into feature selection, model interpretation, and the effectiveness of PCA in enhancing classification tasks in a practical setting.

## `SDS230_FinalProject.pdf` Data Analysis and Exploration Final Project, R, Spring 2021 ([pdf](https://github.com/franklinshe/code-samples/blob/master/SDS230_FinalProject.pdf), [code](https://github.com/franklinshe/code-samples/blob/master/SDS230_FinalProject.Rmd))

In my Data Analysis course, I conducted a study examining the influence of various factors, such as alcohol consumption, sex, and study time, on student grades in Portuguese secondary schools. Using multiple regression, ANOVA, permutation tests, and bootstrap methods, the project delved into significant correlations and predictors of academic performance. Our findings highlighted the negative impact of alcohol consumption on grades and revealed significant grade differences between genders and schools. Transformations and interaction terms further refined our models, providing a nuanced understanding of the data. The .Rmd file is also included in this repository.

## `exchange.sol` Decentralized CFMM Exchange, Solidity, Spring 2023, ([code](https://github.com/franklinshe/code-samples/blob/master/exchange.sol))

After taking a course on Blockchain and Cryptocurrency, I learned about permissionless and secure market protocols and implemented a constant function market maker (CFMM) modeled after the Uniswap V1 Protocol. I also created an ERC-20 token and a web client allowing users to swap tokens or provide or remove liquidity. This is an diagram of a sandwich attack, a form of front-running, that this implementation attempts to curb through limits on slippage.

![image](https://github.com/franklinshe/code-samples/assets/65642896/9a4f9f89-6641-4706-9d12-167378259c33)

## `sysfile.c`  mCertikos Operating System, C, Fall 2022 ([code](https://github.com/franklinshe/code-samples/blob/master/sysfile.c#L582))

In my Operating Systems class, I built out a micro certified OS kernel in C running on the QEMU open-source simulator. I implemented components of physical and virtual memory, process and thread management, trap and interrupt handling, scheduling and concurrency, and a file system. For our final project, my partner and I added support for file sharing synchronization through an implementation of BSD file locks ([flock](https://man7.org/linux/man-pages/man2/flock.2.html)). This defined and solved the mutual exclusion issue when multiple user threads open one file. Here is a usage example:

```{c}
/* acquire shared lock in non-blocking mode */
if (flock(fd, LOCK_SH | LOCK_NB) == -1) {
    exit(1);
}
/* non-atomically upgrade to exclusive lock */
if (flock(fd, LOCK_EX) == -1) {
    exit(1);
}
/* release lock */
if (flock(fd, LOCK_UN) == -1) {
    exit(1);
}
```

### Other Projects

- [Command-line TeX-like compiler](https://github.com/franklinshe/tex-macro-processor) in C
- [Ethereum blockchain backend buy/sell marketplace](https://github.com/franklinshe/marketplace-dapp) in React and Solidity

