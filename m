Voici mes entités ::
package com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa;
import com.socgen.unibank.platform.domain.URN;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import com.socgen.unibank.domain.base.DocumentStatus;
import java.util.Date;
import java.util.List;

@Entity
@Table(name = "document")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DocumentEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String name;

    @Column(nullable = false)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DocumentStatus status;

    @OneToMany(cascade = CascadeType.ALL, mappedBy = "document", orphanRemoval = true, fetch = FetchType.EAGER)
    private List<MetaDataEntity> metadata;


    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "creation_date", nullable = false)
    private Date creationDate;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "modification_date", nullable = false)
    private Date modificationDate;

    @Column(nullable = false)
    private String createdBy;

    @Column(nullable = false)
    private String modifiedBy;

    @ManyToOne
    @JoinColumn(name = "folder_id")
    private FolderEntity folder;
}



package com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;
import java.util.List;

@Entity
@Table(name = "folder")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class FolderEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String name;

    @ManyToOne
    @JoinColumn(name = "parent_folder_id")
    private FolderEntity parentFolder;

    @OneToMany(mappedBy = "parentFolder", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    private List<FolderEntity> subFolders;

    @OneToMany(mappedBy = "folder", cascade = CascadeType.ALL)
    private List<DocumentEntity> documents;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(nullable = false)
    private Date creationDate;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(nullable = false)
    private Date modificationDate;

    @Column(nullable = false)
    private String createdBy;

    @Column(nullable = false)
    private String modifiedBy;
}


package com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;

@Entity
@Table(name = "document_version")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DocumentVersionEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "document_id", nullable = false)
    private DocumentEntity document;

    @Column(nullable = false)
    private Integer versionNumber;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String description;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "creation_date", nullable = false)
    private Date creationDate;

    @Column(nullable = false)
    private String createdBy;
}


package com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "metadata")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class MetaDataEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "document_id", nullable = false)
    private DocumentEntity document;

    @Column(nullable = false)
    private String key;

    @Column(nullable = false)
    private String value;
}

Voici mon Api ::
package com.socgen.unibank.services.autotest.model;
import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.services.autotest.model.model.*;
import com.socgen.unibank.services.autotest.model.usecases.*;
import io.leangen.graphql.annotations.GraphQLQuery;
import io.leangen.graphql.annotations.GraphQLRootContext;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import org.springframework.web.bind.annotation.*;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
@Tag(name = "Document Management")
@RequestMapping(name = "documents", produces = "application/json")
public interface DocumentAPI extends GetDocumentList, CreateDocument , GetDocumentVersions , CreateDocumentVersion , GetFolder ,CreateFolder {
    @Operation(
        summary = "Lists des documents",
        parameters = {
            @Parameter(ref = "entityIdHeader", required = true),

        }
    )
    @GetMapping("/documents")
    @GraphQLQuery(name = "documentEntries")
   // @RolesAllowed(Permissions.IS_GUEST)
    @Override
    List<DocumentDTO> handle(GetDocumentEntryListRequest input, @GraphQLRootContext @ModelAttribute RequestContext ctx);
    @Operation(
        summary = "Create a new document",
        parameters = {
        @Parameter(ref = "entityIdHeader", required = true),
        }
    )
    @PostMapping("/document")
    @GraphQLQuery(name = "createDocument")
    //@RolesAllowed(Permissions.IS_GUEST)
    @Override
    DocumentDTO handle(@RequestBody CreateDocumentEntryRequest input, @GraphQLRootContext @ModelAttribute RequestContext ctx);
    @Operation(
        summary = "Get document versions",
        parameters = {
            @Parameter(name = "documentId", description = "ID of the document", required = true, in = ParameterIn.PATH),
            @Parameter(ref = "entityIdHeader", required = true),
        }
    )
    @GetMapping("/documents/{documentId}/versions")
    @GraphQLQuery(name = "documentVersions")
    List<DocumentVersionDTO> handle(GetDocumentVersionEntryRequest input, @GraphQLRootContext @ModelAttribute RequestContext ctx);
    @Operation(
        summary = "Add a new document version",
        parameters = {
            @Parameter(ref = "entityIdHeader", required = true),
        }
    )
    @PostMapping("/documents/{documentId}/versions")
    @GraphQLQuery(name = "addDocumentVersion")
    @Override
    DocumentVersionDTO handle(@RequestBody CreateDocumentVersionRequest input, @GraphQLRootContext @ModelAttribute RequestContext ctx);


    @Operation
        (summary = "Get list of folders",
            parameters = {
                @Parameter(ref = "entityIdHeader", required = true),

            }
        )
    @GetMapping("/folders")
    @Override
    List<FolderDTO> handle(GetFolderRequest input, @ModelAttribute RequestContext ctx);

    @Operation(
        summary = "Create a new folder",
        parameters = {
            @Parameter(ref = "entityIdHeader", required = true),

        }
    )
    @PostMapping("/folder")
    @Override
    FolderDTO handle(@RequestBody CreateFolderRequest input, @ModelAttribute RequestContext ctx);


}


Question :: pouruoi tous mes endopoints fonctionne sauf :
 @Operation
        (summary = "Get list of folders",
            parameters = {
                @Parameter(ref = "entityIdHeader", required = true),

            }
        )
    @GetMapping("/folders")
    @Override
    List<FolderDTO> handle(GetFolderRequest input, @ModelAttribute RequestContext ctx);  


Voici ma logique ::
//package com.socgen.unibank.services.autotest.core.usecases;
//
//import com.socgen.unibank.platform.models.RequestContext;
//import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.FolderEntity;
//import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.FolderRepository;
//import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
//import com.socgen.unibank.services.autotest.model.model.FolderDTO;
//import com.socgen.unibank.services.autotest.model.model.GetFolderRequest;
//import com.socgen.unibank.services.autotest.model.model.MetaDataDTO;
//import com.socgen.unibank.services.autotest.model.usecases.GetFolder;
//import lombok.AllArgsConstructor;
//import org.springframework.stereotype.Service;
//
//import java.util.List;
//import java.util.stream.Collectors;
//
//@AllArgsConstructor
//@Service
//public class GetFolderImpl implements GetFolder {
//
//    private final FolderRepository folderRepository;
//
//    @Override
//    public List<FolderDTO> handle(GetFolderRequest input, RequestContext context) {
//        List<FolderEntity> folders = input.getFolderId() != null
//            ? List.of(folderRepository.findById(input.getFolderId()).orElseThrow(() -> new IllegalArgumentException("Folder not found")))
//            : folderRepository.findAll();
//
//        return folders.stream()
//            .map(folder -> new FolderDTO(
//                folder.getId(),
//                folder.getName(),
//                folder.getParentFolder() != null ? folder.getParentFolder().getId() : null,
//                folder.getCreationDate(),
//                folder.getModificationDate(),
//                folder.getCreatedBy(),
//                folder.getModifiedBy(),
//                folder.getDocuments() != null ? folder.getDocuments().stream() // Conversion de documents liés
//                    .map(document -> new DocumentDTO(
//                        document.getId(),
//                        document.getName(),
//                        document.getDescription(),
//                        document.getStatus(),
//                        document.getMetadata() != null ? document.getMetadata().stream()
//                            .map(meta -> new MetaDataDTO(
//                                meta.getKey(),
//                                meta.getValue()
//                            )).collect(Collectors.toList()) : null,
//                        document.getCreationDate(),
//                        document.getModificationDate(),
//                        null,
//                        null
//                    )).collect(Collectors.toList()) : null,
//                folder.getSubFolders() != null ? folder.getSubFolders().stream() // Conversion de sous-dossiers
//                    .map(subFolder -> new FolderDTO(
//                        subFolder.getId(),
//                        subFolder.getName(),
//                        subFolder.getParentFolder() != null ? subFolder.getParentFolder().getId() : null,
//                        subFolder.getCreationDate(),
//                        subFolder.getModificationDate(),
//                        subFolder.getCreatedBy(),
//                        subFolder.getModifiedBy(),
//                        null, // Assuming sub-folder documents are not needed here
//                        null  // Assuming sub-folder sub-folders are not needed here
//                    )).collect(Collectors.toList()) : null
//            ))
//            .collect(Collectors.toList());
//    }
//}


package com.socgen.unibank.services.autotest.core.usecases;

import com.socgen.unibank.domain.base.AdminUser;
import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.FolderEntity;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.FolderRepository;
import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
import com.socgen.unibank.services.autotest.model.model.FolderDTO;
import com.socgen.unibank.services.autotest.model.model.GetFolderRequest;
import com.socgen.unibank.services.autotest.model.model.MetaDataDTO;
import com.socgen.unibank.services.autotest.model.usecases.GetFolder;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@AllArgsConstructor
@Service
public class GetFolderImpl implements GetFolder {

    private final FolderRepository folderRepository;

    @Override
    public List<FolderDTO> handle(GetFolderRequest input, RequestContext context) {
        List<FolderEntity> folders = input.getFolderId() != null
            ? List.of(folderRepository.findById(input.getFolderId()).orElseThrow(() -> new IllegalArgumentException("Folder not found")))
            : folderRepository.findAll();

        return folders.stream()
            .map(folder -> new FolderDTO(
                folder.getId(),
                folder.getName(),
                folder.getParentFolder() != null ? folder.getParentFolder().getId() : null,
                folder.getCreationDate(),
                folder.getModificationDate(),
                folder.getCreatedBy(),
                folder.getModifiedBy(),
                folder.getDocuments() != null ? folder.getDocuments().stream()
                    .map(document -> new DocumentDTO(
                        document.getId(),
                        document.getName(),
                        document.getDescription(),
                        document.getStatus(),
                        document.getMetadata() != null ? document.getMetadata().stream()
                            .map(meta -> new MetaDataDTO(
                                meta.getKey(),
                                meta.getValue()
                            )).collect(Collectors.toList()) : null,
                        document.getCreationDate(),
                        document.getModificationDate(),
                        document.getCreatedBy() != null ? new AdminUser(document.getCreatedBy()) : null, // Assuming AdminUser has a constructor that takes a String
                        document.getModifiedBy() != null ? new AdminUser(document.getModifiedBy()) : null, // Assuming AdminUser has a constructor that takes a String
                        null // Assuming folder field in DocumentDTO is not necessary here
                    )).collect(Collectors.toList()) : null,
                folder.getSubFolders() != null ? folder.getSubFolders().stream()
                    .map(subFolder -> new FolderDTO(
                        subFolder.getId(),
                        subFolder.getName(),
                        subFolder.getParentFolder() != null ? subFolder.getParentFolder().getId() : null,
                        subFolder.getCreationDate(),
                        subFolder.getModificationDate(),
                        subFolder.getCreatedBy(),
                        subFolder.getModifiedBy(),
                        null, // Assuming sub-folder documents are not needed here
                        null  // Assuming sub-folder sub-folders are not needed here
                    )).collect(Collectors.toList()) : null
            ))
            .collect(Collectors.toList());
    }
}


voici mon erreur ::
at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:135)
	at org.springframework.security.web.session.SessionManagementFilter.doFilter(SessionManagementFilter.java:131)
	at org.springframework.security.web.session.SessionManagementFilter.doFilter(SessionManagementFilter.java:85)
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:187)
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:174)
	at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:135)
	at org.springframework.security.web.authentication.AnonymousAuthenticationFilter.doFilter(AnonymousAuthenticationFilter.java:100)
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:187)
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:174)
	at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:135)
	at org.springframework.security.web.servletapi.SecurityContextHolderAwareRequestFilter.doFilter(SecurityContextHolderAwareRequestFilter.java:179)
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:187)
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:174)
	at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:135)
	at org.springframework.security.web.savedrequest.RequestCacheAwareFilter.doFilter(RequestCacheAwareFilter.java:63)
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:187)
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:174)
	at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:135)
	at com.socgen.unibank.platform.springboot.config.web.RequestFilter.doFilterInternal(RequestFilter.java:131)
	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:116)
	...
Caused by: java.lang.reflect.InvocationTargetException
	at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:77)
	at java.base/jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.base/java.lang.reflect.Method.invoke(Method.java:569)
	at com.socgen.unibank.platform.springboot.config.UseCaseMapping.handle(UseCaseMapping.java:65)
	at com.socgen.unibank.platform.springboot.config.web.ControllersConfig.lambda$configureEndpoints$1(ControllersConfig.java:192)
	... 127 more
Caused by: org.hibernate.LazyInitializationException: failed to lazily initialize a collection of role: com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.FolderEntity.documents: could not initialize proxy - no Session
	at org.hibernate.collection.spi.AbstractPersistentCollection.throwLazyInitializationException(AbstractPersistentCollection.java:635)
	at org.hibernate.collection.spi.AbstractPersistentCollection.withTemporarySessionIfNeeded(AbstractPersistentCollection.java:218)
	at org.hibernate.collection.spi.AbstractPersistentCollection.initialize(AbstractPersistentCollection.java:615)
	at org.hibernate.collection.spi.AbstractPersistentCollection.read(AbstractPersistentCollection.java:136)
	at org.hibernate.collection.spi.PersistentBag.iterator(PersistentBag.java:366)
	at java.base/java.util.Spliterators$IteratorSpliterator.estimateSize(Spliterators.java:1865)
	at java.base/java.util.Spliterator.getExactSizeIfKnown(Spliterator.java:414)
	at java.base/java.util.stream.AbstractPipeline.copyInto(AbstractPipeline.java:508)
	at java.base/java.util.stream.AbstractPipeline.wrapAndCopyInto(AbstractPipeline.java:499)
	at java.base/java.util.stream.ReduceOps$ReduceOp.evaluateSequential(ReduceOps.java:921)
	at java.base/java.util.stream.AbstractPipeline.evaluate(AbstractPipeline.java:234)
	at java.base/java.util.stream.ReferencePipeline.collect(ReferencePipeline.java:682)
	at com.socgen.unibank.services.autotest.core.usecases.GetFolderImpl.lambda$handle$4(GetFolderImpl.java:126)
	at java.base/java.util.stream.ReferencePipeline$3$1.accept(ReferencePipeline.java:197)
	...
	at com.socgen.unibank.services.autotest.core.usecases.GetFolderImpl.handle(GetFolderImpl.java:140)
