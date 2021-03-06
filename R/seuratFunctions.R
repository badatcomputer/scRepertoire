#' Adding clonotype information to a seurat object
#'
#' @param df The product of CombineContig()
#' @param seurat The seurat object to attach
#' @param call How to call the clonotype - based on genes, CDR3 nt, or CDR3 aa sequence, or the combination of genes and nucleotide sequence
#' @param groupBy The column label in which clonotype frequency will be calculated
#' @param cloneType The bins for the grouping based on frequency
#' @export
combineSeurat <- function(df,
                          seurat,
                          call = c("gene", "nt", "aa", "gene+nt"),
                          groupBy = c("none", "sample", "ID", ...),
                          cloneTypes = c(Single = 1, Small = 5, Medium = 20, Large = 100, Hyperexpanded = 500)) {
    df <- if(class(df) != "list") list(df) else df
    cloneTypes <- c(None = 0, cloneTypes)
    if (length(df) == 0 | length(seurat) == 0) {
        stop("Make sure you are adding the combined contigs and Seurat object to the combineSeurat() function")
    }
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
    Con.df <- NULL
    if (groupBy == "none") {
        for (i in seq_along(df)) {
            data <- data.frame(df[[i]], stringsAsFactors = F)
            data2 <- data[,c("barcode", call)]
            data2 <- unique(data2)
            data2 <- data2 %>%
                group_by(data2[,call]) %>%
                summarise(Frequency = n())
            colnames(data2)[1] <- call
            data2 <- na.omit(data2)
            data <- merge(data, data2, by = call, all = T)
            Con.df <- rbind.data.frame(Con.df, data)
            data <- NULL

        }
    }
    else if (groupBy != "none") {

        data <- bind_rows(df)
        data2 <- data[,c("barcode", call, groupBy)]
        data2 <- unique(data2)
        data2 <- data2 %>%
            group_by(data2[,call], data2[,groupBy]) %>%
            summarise(Frequency = n())
        colnames(data2)[1] <- call
        colnames(data2)[2] <- groupBy
        data2 <- na.omit(data2)
        x <- unique(data[,groupBy])
#        data2<- data2[ , -which(names(data2) %in% c(groupBy))]
        Con.df <- NULL
        for (i in seq_along(x)) {
            sub1 <- subset(data, data[,groupBy] == x[i])
            sub2 <- subset(data2, data2[,groupBy] == x[i])
            merge <- merge(sub1, sub2, by=call)
            Con.df <- rbind.data.frame(Con.df, merge)
        }
    }
    Con.df$cloneType <- NA
    for (x in seq_along(cloneTypes)) {
        names(cloneTypes)[x] <- paste0(names(cloneTypes[x]), ' (', cloneTypes[x-1], ' < X <= ', cloneTypes[x], ')')
    }
    for (i in 2:length(cloneTypes)) {
        Con.df$cloneType <- ifelse(Con.df$Frequency > cloneTypes[i-1] & Con.df$Frequency <= cloneTypes[i], names(cloneTypes[i]), Con.df$cloneType)
    }

    PreMeta <- Con.df[,c("barcode", "CTgene", "CTnt", "CTaa", "CTstrict", "Frequency", "cloneType")]
    PreMeta <- unique(PreMeta)
    rownames(PreMeta) <- PreMeta$barcode
    seurat <- Seurat::AddMetaData(seurat, PreMeta)
}
#' Highlighting specific clonotypes in Seurat
#'
#' @param seurat The seurat object to attach
#' @param call How to call the clonotype - based on genes, CDR3 nt, or CDR3 aa sequence or the combination of genes and nucleotide sequence
#' @param sequence The specifc sequence or sequence to highlight
#'
#' @export
highlightClonotypes <- function(seurat,
                                call = c("gene", "nt", "aa", "gene+nt"),
                                sequence = NULL){
    if (class(seurat) != "Seurat"){
        stop("Object indicated is not of class 'Seurat', make sure you are using the correct data.")
    }
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
    meta <- seurat@meta.data
    meta$highlight <- NA
    for(i in seq_along(sequence)) {
        meta$highlight <- ifelse(meta[,call] == sequence[i], paste("Clonotype", i, sep=""),  meta$highlight)
    }
    names <- rownames(meta)
    meta <- data.frame(meta[,c("highlight")])
    rownames(meta) <- names
    colnames(meta)[1] <- "highlight"
    seurat <- AddMetaData(seurat, meta)

}

#' Exploring interaction of clonotypes by seurat dynamics
#'
#' @param seurat The seurat object to attach
#' @param call How to call the clonotype - based on genes, CDR3 nt, or CDR3 aa sequence or the combination of genes and nucleotide sequence
#' @param compare The column label to visualize
#' @param facet The column label to seperate
#'
#' @export
alluvialClonotypes <- function(seurat,
                          call = c("gene", "nt", "aa", "gene+nt"),
                          compare = c("cluster", ...),
                          facet = NULL) {

    if (class(seurat) != "Seurat"){
        stop("Object indicated is not of class 'Seurat', make sure you are using the correct data.")
    }
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
    if (length(compare) > 1) {
        stop("Only one comparison can be made for the sake of sanity, if you'd like to seperate by another variable, use the facet call.")
    }



    meta <- data.frame(seurat@meta.data, seurat@active.ident)
    n <- which(colnames(meta) == "seurat.active.ident")
    colnames(meta)[n] <- "cluster"

    if (is.na(meta[,compare])) {
        stop("Make sure you are using the right variable name.")
    }

    plot <- ggplot(meta,
                   aes(axis1 = meta[,compare], axis2 = reorder(meta[,call], Frequency))) +
        geom_alluvium(aes(fill=meta[,compare])) +
        geom_stratum(fill = "grey", color = "black", lwd=0.1) +
        theme_classic() +
        labs(fill = compare) +
        ylab(compare) +
        ggfittext::geom_fit_text(aes(label = meta[,compare]), stat = "stratum", infer.label = TRUE, reverse = T, min.y=min(table(meta[,compare]))) +
        guides(fill=F) +
        theme(axis.text.x = element_blank(),
              axis.ticks.x = element_blank())
    if (length(facet) == 1 & length(facet) < 2) {
        plot <- plot + facet_wrap(.~meta[,facet], scales="free_y")
    }
    else if (length(facet) == 0) {
        plot <- plot
    }
    else {
        stop("Only can facet on one item at a time, try multiple calls with different facets.")
    }
    suppressWarnings(print(plot))
}
