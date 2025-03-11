je suis entrain de créer une plateforme de gestion de documents ou :
l'utilisateur se connecte :
créer d'abord un dossier . Dans le Dossier il peut crée plusieurs Documents , Maintenant voici Mon Folder et Mon Document :
package com.socgen.unibank.services.autotest.model.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FolderDTO {
    private Long id;
    private String name;
    private Long parentFolderId; // ID du dossier parent pour gérer les hiérarchies
    private Date creationDate;
    private Date modificationDate;
    private String createdBy;
    private String modifiedBy;
    private List<DocumentDTO> documents;
    private List<FolderDTO> subFolders;
}

package com.socgen.unibank.services.autotest.model.model;
import com.socgen.unibank.domain.base.AdminUser;
import com.socgen.unibank.domain.base.DocumentStatus;
import com.socgen.unibank.platform.domain.Domain;
import com.socgen.unibank.platform.domain.URN;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.Date;
import java.util.List;
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DocumentDTO {

    private Long documentId;
   private String name;
   private String description;
   private DocumentStatus status;
   private List<MetaDataDTO> metadata;
    private Date creationDate;
    private Date modificationDate;
    private AdminUser createdBy;
    private AdminUser modifiedBy;
    private FolderDTO folder;

}

package com.socgen.unibank.services.autotest.model.usecases;

import com.socgen.unibank.platform.domain.Command;
import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.services.autotest.model.model.CreateFolderRequest;
import com.socgen.unibank.services.autotest.model.model.FolderDTO;

public interface CreateFolder  extends Command {
    FolderDTO handle(CreateFolderRequest input, RequestContext context);
}

package com.socgen.unibank.services.autotest.model.usecases;
import com.socgen.unibank.platform.domain.Command;
import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.services.autotest.model.model.CreateDocumentEntryRequest;
import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
public interface CreateDocument  extends Command {
    DocumentDTO handle(CreateDocumentEntryRequest input, RequestContext context);
}

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

    @OneToMany(mappedBy = "folder", cascade = CascadeType.ALL, fetch = FetchType.EAGER)
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


package com.socgen.unibank.services.autotest.core.usecases;

import com.socgen.unibank.domain.base.AdminUser;
import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.services.autotest.core.DocumentRepository;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.EntityToDTOConverter;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.FolderEntity;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.FolderRepository;
import com.socgen.unibank.services.autotest.model.model.CreateDocumentEntryRequest;
import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
import com.socgen.unibank.services.autotest.model.model.MetaDataDTO;
import com.socgen.unibank.services.autotest.model.usecases.CreateDocument;
import org.springframework.stereotype.Service;
import com.socgen.unibank.domain.base.DocumentStatus;
import java.util.Date;
import java.util.stream.Collectors;

@Service
public class CreateDocumentImpl implements CreateDocument {

    private final DocumentRepository documentRepository;
    private final FolderRepository folderRepository;

    public CreateDocumentImpl(DocumentRepository documentRepository, FolderRepository folderRepository) {
        this.documentRepository = documentRepository;
        this.folderRepository = folderRepository;
    }

    @Override
    public DocumentDTO handle(CreateDocumentEntryRequest input, RequestContext context) {
        DocumentDTO newDocument = new DocumentDTO();
        newDocument.setName(input.getName());
        newDocument.setDescription(input.getDescription());
        newDocument.setStatus(DocumentStatus.CREATED);
        newDocument.setMetadata(input.getMetadata().entrySet().stream()
            .map(entry -> new MetaDataDTO(entry.getKey(), entry.getValue()))
            .collect(Collectors.toList()));
        newDocument.setCreationDate(new Date());
        newDocument.setModificationDate(new Date());
        newDocument.setCreatedBy(new AdminUser("usmane@socgen.com"));
        newDocument.setModifiedBy(new AdminUser("usmane@socgen.com"));

        if (input.getFolderId() != null) {
            FolderEntity folder = folderRepository.findById(input.getFolderId())
                .orElseThrow(() -> new IllegalArgumentException("Folder not found"));
            newDocument.setFolder(EntityToDTOConverter.convertFolderEntityToDTO(folder));
        }

        documentRepository.saveDocument(newDocument);
        return newDocument;
    }
}


package com.socgen.unibank.services.autotest.core.usecases;

import com.socgen.unibank.platform.models.RequestContext;

import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.FolderEntity;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.FolderRepository;
import com.socgen.unibank.services.autotest.model.model.CreateFolderRequest;
import com.socgen.unibank.services.autotest.model.model.FolderDTO;
import com.socgen.unibank.services.autotest.model.usecases.CreateFolder;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Date;

@AllArgsConstructor
@Service
public class CreateFolderImpl implements CreateFolder {

    private final FolderRepository folderRepository;

    @Override
    public FolderDTO handle(CreateFolderRequest input, RequestContext context) {
        FolderEntity folderEntity = new FolderEntity();
        folderEntity.setName(input.getName());
        folderEntity.setCreatedBy(input.getCreatedBy());
        folderEntity.setCreationDate(new Date());
        folderEntity.setModificationDate(new Date());
        folderEntity.setModifiedBy(input.getCreatedBy());

        // Définir le dossier parent, si disponible
        if (input.getParentFolderId() != null) {
            FolderEntity parentFolder = folderRepository.findById(input.getParentFolderId())
                .orElseThrow(() -> new IllegalArgumentException("Parent folder not found"));
            folderEntity.setParentFolder(parentFolder);
        }

        FolderEntity savedFolder = folderRepository.save(folderEntity);
        return new FolderDTO(
            savedFolder.getId(),
            savedFolder.getName(),
            savedFolder.getParentFolder() != null ? savedFolder.getParentFolder().getId() : null,
            savedFolder.getCreationDate(),
            savedFolder.getModificationDate(),
            savedFolder.getCreatedBy(),
            savedFolder.getModifiedBy(),
            null,
            null
        );
    }
}


Mes migrations ::
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
        http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-3.8.xsd">

    <!-- ChangeSet for Folder table -->
    <changeSet id="20231001-1" author="developer">
        <createTable tableName="folder">
            <column name="id" type="BIGINT" autoIncrement="true">
                <constraints primaryKey="true"/>
            </column>
            <column name="name" type="VARCHAR(255)">
                <constraints nullable="false" unique="true"/>
            </column>
            <column name="parent_folder_id" type="BIGINT"/>
            <column name="creation_date" type="TIMESTAMP">
                <constraints nullable="false"/>
            </column>
            <column name="modification_date" type="TIMESTAMP">
                <constraints nullable="false"/>
            </column>
            <column name="created_by" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
            <column name="modified_by" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
        </createTable>

        <addForeignKeyConstraint
            baseTableName="folder"
            baseColumnNames="parent_folder_id"
            referencedTableName="folder"
            referencedColumnNames="id"
            constraintName="fk_folder_parent"/>
    </changeSet>

    <!-- ChangeSet for Document table -->
    <changeSet id="20231001-2" author="developer">
        <createTable tableName="document">
            <column name="id" type="BIGINT" autoIncrement="true">
                <constraints primaryKey="true"/>
            </column>
            <column name="name" type="VARCHAR(255)">
                <constraints nullable="false" unique="true"/>
            </column>
            <column name="description" type="VARCHAR(512)">
                <constraints nullable="false"/>
            </column>
            <column name="status" type="VARCHAR(50)">
                <constraints nullable="false"/>
            </column>
            <column name="folder_id" type="BIGINT"/>
            <column name="creation_date" type="TIMESTAMP">
                <constraints nullable="false"/>
            </column>
            <column name="modification_date" type="TIMESTAMP">
                <constraints nullable="false"/>
            </column>
            <column name="created_by" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
            <column name="modified_by" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
        </createTable>

        <addForeignKeyConstraint
            baseTableName="document"
            baseColumnNames="folder_id"
            referencedTableName="folder"
            referencedColumnNames="id"
            constraintName="fk_document_folder"/>
    </changeSet>

    <!-- ChangeSet for Metadata table -->
    <changeSet id="20231001-3" author="developer">
        <createTable tableName="metadata">
            <column name="id" type="BIGINT" autoIncrement="true">
                <constraints primaryKey="true"/>
            </column>
            <column name="document_id" type="BIGINT">
                <constraints nullable="false"/>
            </column>
            <column name="key" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
            <column name="value" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
        </createTable>

        <addForeignKeyConstraint
            baseTableName="metadata"
            baseColumnNames="document_id"
            referencedTableName="document"
            referencedColumnNames="id"
            constraintName="fk_metadata_document"/>
    </changeSet>

    <!-- ChangeSet for DocumentVersion table -->
    <changeSet id="20231001-4" author="developer">
        <createTable tableName="document_version">
            <column name="id" type="BIGINT" autoIncrement="true">
                <constraints primaryKey="true"/>
            </column>
            <column name="document_id" type="BIGINT">
                <constraints nullable="false"/>
            </column>
            <column name="version_number" type="INT">
                <constraints nullable="false"/>
            </column>
            <column name="name" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
            <column name="description" type="VARCHAR(512)">
                <constraints nullable="false"/>
            </column>
            <column name="creation_date" type="TIMESTAMP">
                <constraints nullable="false"/>
            </column>
            <column name="created_by" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
        </createTable>

        <addForeignKeyConstraint
            baseTableName="document_version"
            baseColumnNames="document_id"
            referencedTableName="document"
            referencedColumnNames="id"
            constraintName="fk_document_version_document"/>
    </changeSet>
</databaseChangeLog>


Question :: je te demande juste de gérer au moment de la création du Document de pouvoir upload un ou plusieurs fichiers sous format 'pdf' , ajoute les champs nécessaies dans DocumentEntity et DocumentDTO , fais les usecases correspondants ,schant que tu dois respecter la signature des méthodes comme je l'ai fait puis corrige les logiues et gére la migarion:
sachant que les fichiers une fois upload tu utilses une Injection de S3 client pour appeler une méthode upload fichier qui prend deux params le file et le Path 
