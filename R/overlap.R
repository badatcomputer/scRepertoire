#' Examining the clonal overlap between samples
#'
#' @param df The product of CombineContig() or the seurat object after combineSeurat()
#' @param call How to call the clonotype - CDR3 gene, CDR3 nt or CDR3 aa, or CDR3+nucleotide
#' @param method The method to calculate the overlap, either the overlap coefficient or morisita index
#' @param exportTable Exports a table of the data into the global environment in addition to the visualization
#'
#' @export
clonalOverlap <- function(df,
                    call = c("gene", "nt", "aa", "gene+nt"),
                    method = c("overlap", "morisita"),
                    exportTable = F){
    if (call == "gene") {
        call <- "CTgene"
    } else if(call == "nt") {
        call <- "CTnt"
    } else if (call == "aa") {
        call <- "CTaa"
    } else {
        call <- "CTstrict"
    }

    if (class(df)[1] == "Seurat") {
        meta <- data.frame(df@meta.data, df@active.ident)
        colnames(meta)[length(meta)] <- "cluster"
        unique <- stringr::str_sort(as.character(unique(meta$cluster)), numeric = TRUE)
        meta$barcode <- rownames(meta)
        df <- NULL
        for (i in seq_along(unique)) {
            subset <- subset(meta, meta[,"cluster"] == unique[i])
            df[[i]] <- subset
        }
        names(df) <- unique
    }
    else if (class(df)[1] != "Seurat") {
        df <- df[order(names(df))]
    }

    num_samples <- length(df[])
    names_samples <- names(df)
    coef_matrix <- data.frame(matrix(NA, num_samples, num_samples))
    colnames(coef_matrix) <- names_samples
    rownames(coef_matrix) <- names_samples
    if (method == "overlap") {

        for (i in 1:num_samples){
          df.i <- df[[i]]
          df.i <- df.i[,c("barcode",call)]
          df.i_unique <- df.i[!duplicated(df.i$barcode),]

          for (j in 1:num_samples){
            if (i >= j){
              next
            }
            else {
              df.j <- df[[j]]
              df.j <- df.j[,c("barcode",call)]
              df.j_unique <- df.j[!duplicated(df.j$barcode),]
              overlap <- length(intersect(df.i_unique[,call], df.j_unique[,call]))
              coef_matrix[i,j] <- overlap/min(length(df.i_unique[,call]), length(df.j_unique[,call]))
            }
          }
        }
    }
    else if (method == "morisita") {

        for (i in 1:num_samples){
            df.i <- df[[i]]
            df.i <- data.frame(table(df.i[,call]))
            colnames(df.i) <- c(call, 'Count')
            df.i[,2] <- as.numeric(df.i[,2])

            for (j in 1:num_samples){
                if (i >= j){
                    next
                }
                else {
                    df.j <- df[[j]]
                    df.j <- data.frame(table(df.j[,call]))
                    colnames(df.j) <- c(call, 'Count')
                    df.j[,2] <- as.numeric(df.j[,2])

                    merged <- merge(df.i, df.j, by = call, all = T)
                    merged[is.na(merged)] <- 0
                    sum.df.i <- sum(df.i[,2])
                    sum.df.j <- sum(df.j[,2])
                    coef.i.j <- 2 * sum(merged[,2] * merged[,3] / sum.df.j) / sum.df.j/
                        ((sum((df.i[,2] / sum.df.i)^2) + sum((df.j[,2] / sum.df.j)^2)))

                    coef_matrix[i,j] <- coef.i.j
                }
            }
        }

    }
    coef_matrix$names <- rownames(coef_matrix)
    if (exportTable == T) {
        clonalOverlap_output <<- coef_matrix
    }
    coef_matrix <- suppressMessages(reshape2::melt(coef_matrix))
    coef_matrix <- coef_matrix[,-1]
    col <- colorblind_vector(7)
    values <- stringr::str_sort(as.character(unique(coef_matrix$names)), numeric = TRUE)
    values2 <- quiet(dput(values))
    coef_matrix$variable <- factor(coef_matrix$variable, levels = values2)
    coef_matrix$names <- factor(coef_matrix$names, levels = values2)
    plot <- ggplot(coef_matrix, aes(x=names, y=variable, fill=value)) +
        geom_tile() +
        geom_text(aes(label = round(value, digits = 3))) +
        scale_fill_gradient2(high = col[1], mid = col[4], midpoint = ((range(na.omit(coef_matrix$value)))/2)[2], low=col[7], na.value = "white") +
        labs(fill = method) +
        theme_classic() +
        theme(axis.title = element_blank())
    suppressWarnings(print(plot))
}
