#' Examine the clonal diversity of samples
#'
#' @param df The product of CombineContig() or the seurat object after combineSeurat()
#' @param call How to call the clonotype - CDR3 gene, CDR3 nt or CDR3 aa, or CDR3+nucleotide
#' @param colorBy The column header for which you would like to analyze the data
#' @param exportTable Exports a table of the data into the global environment in addition to the visualization
#'
#' @export
clonalDiversity <- function(df,
                            call = c("gene", "nt", "aa", "gene+nt"),
                            colorBy = c("samples", ...),
                            exportTable = F) {
    if (call == "gene") {
        call <- "CTgene"
    } else if(call == "nt") {
        call <- "CTnt"
    } else if (call == "aa") {
        call <- "CTaa"
    } else if (call == "gene+nt") {
        call <- "CTstrict"
    } else {
        stop("Are you sure you made the right call? ", .call = F)
    }
    if (class(df)[1] == "Seurat") {
        Type <- "Seurat"
    }
    else if (class(df)[1] != "Seurat") {
        Type <- "list"
    }
    if (class(df)[1] == "Seurat") {
        meta <- data.frame(df@meta.data, df@active.ident)
        colnames(meta)[length(meta)] <- "cluster"
        unique <- stringr::str_sort(as.character(unique(meta[,colorBy])), numeric = TRUE)
        df <- NULL
        for (i in seq_along(unique)) {
            subset <- subset(meta, meta[,colorBy] == unique[i])
            df[[i]] <- subset
        }
        names(df) <- unique
    }
    mat <- NULL
    if (colorBy == "samples") {
        for (i in seq_along(df)) {
            data <- as.data.frame(table(df[[i]][,call]))
            w <- vegan::diversity(data[,"Freq"], index = "shannon")
            x <- vegan::diversity(data[,"Freq"], index = "invsimpson")
            y <- vegan::estimateR(data[,"Freq"])[2] #Chao
            z <- vegan::estimateR(data[,"Freq"])[4] #ACE
            out <- c(w,x,y,z)
            mat <- rbind.data.frame(mat, out)

        }
        colnames(mat) <- c("Shannon", "Inv.Simpson", "Chao", "ACE")
        rownames(mat) <- names(df)
        mat[,colorBy] <- rownames(mat)
        melt <- reshape2::melt(mat, id.vars = colorBy)
        plot <- ggplot2::ggplot(melt, aes(x, y=value)) +
            geom_jitter(shape=21, size=3, width=0.2, aes(fill=melt[,colorBy]))

    } else {
        for (i in seq_along(df)) {
            data <- as.data.frame(table(df[[i]][,call]))
            if (Type == "list") {
                color <- df[[i]][1,colorBy]
            }
            else if (Type == "Seurat") {
                color <- names(df)[i]
            }
            w <- vegan::diversity(data[,"Freq"], index = "shannon")
            x <- vegan::diversity(data[,"Freq"], index = "invsimpson")
            y <- vegan::estimateR(data[,"Freq"])[2] #Chao
            z <- vegan::estimateR(data[,"Freq"])[4] #ACE
            out <- c(w,x,y,z,color)
            mat <- rbind(mat, out)
        }
        mat <- as.data.frame(mat)
        if (exportTable == T) {
            clonalOverlap_output <<- coef_matrix
        }
        colnames(mat) <- c("Shannon", "Inv.Simpson", "Chao", "ACE", colorBy)
        rownames(mat) <- names(df)
        melt <- suppressWarnings(reshape2::melt(mat, id.vars = colorBy))
        values <- stringr::str_sort(as.character(unique(melt[,colorBy])), numeric = TRUE)
        values2 <- quiet(dput(values))
        melt[,colorBy] <- factor(melt[,colorBy], levels = values2)
        plot <-ggplot2::ggplot(melt, aes(x=melt[,colorBy], y=as.numeric(value))) +
            geom_jitter(shape=21, size=3, width=0.2, aes(fill=melt[,colorBy]))

    }
    col <- length(unique(melt[,colorBy]))

    plot <- plot +
        ylab("Index Score") +
        scale_fill_manual(name = colorBy, values = colorblind_vector(col)) +
        facet_wrap(~variable, scales = "free", ncol = 4) +
        theme_classic() +
        theme(axis.title.x = element_blank(),
              axis.text.x = element_blank(),
              axis.ticks.x = element_blank())
     if (Type != "Seurat") {
         plot <- plot +
             geom_boxplot(alpha=0.4, outlier.alpha = 0)
     }
    if (exportTable == T) {
        clonalDiversity_output <<- mat
    }

    suppressWarnings(print(plot))
}
