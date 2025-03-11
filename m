1. Modification de DocumentEntity :
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

    @Column(name = "file_path")
    private String filePath;

    @Column(name = "file_name")
    private String fileName;

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





2. Modification de DocumentDTO :
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DocumentDTO {
    private Long documentId;
    private String name;
    private String description;
    private DocumentStatus status;
    private List<MetaDataDTO> metadata;
    private String filePath;
    private String fileName;
    private Date creationDate;
    private Date modificationDate;
    private AdminUser createdBy;
    private AdminUser modifiedBy;
    private FolderDTO folder;
    private MultipartFile file; // Pour la requête uniquement
}



3. Modification de CreateDocumentImpl :

@Service
public class CreateDocumentImpl implements CreateDocument {
    private final DocumentRepository documentRepository;
    private final FolderRepository folderRepository;
    private final S3Client s3Client;

    public CreateDocumentImpl(DocumentRepository documentRepository, 
                            FolderRepository folderRepository,
                            S3Client s3Client) {
        this.documentRepository = documentRepository;
        this.folderRepository = folderRepository;
        this.s3Client = s3Client;
    }

    @Override
    public DocumentDTO handle(CreateDocumentEntryRequest input, RequestContext context) {
        // Validation du fichier
        if (input.getFile() == null || input.getFile().isEmpty()) {
            throw new IllegalArgumentException("File is required");
        }
        
        if (!input.getFile().getContentType().equals("application/pdf")) {
            throw new IllegalArgumentException("Only PDF files are allowed");
        }

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

        try {
            // Génération du nom de l'objet dans S3
            String objectName = String.format("documents/%s/%s_%s",
                UUID.randomUUID().toString(),
                System.currentTimeMillis(),
                input.getFile().getOriginalFilename());

            // Upload du fichier vers S3
            s3Client.upload(
                input.getFile().getInputStream(),
                objectName,
                input.getFile().getContentType()
            );

            newDocument.setFilePath(objectName);
            newDocument.setFileName(input.getFile().getOriginalFilename());

        } catch (IOException e) {
            throw new TechnicalException("Error uploading file", e);
        }

        if (input.getFolderId() != null) {
            FolderEntity folder = folderRepository.findById(input.getFolderId())
                .orElseThrow(() -> new IllegalArgumentException("Folder not found"));
            newDocument.setFolder(EntityToDTOConverter.convertFolderEntityToDTO(folder));
        }

        documentRepository.saveDocument(newDocument);
        return newDocument;
    }
}


4. Migration pour ajouter les nouveaux champs :

<changeSet id="20240301-1" author="developer">
    <addColumn tableName="document">
        <column name="file_path" type="VARCHAR(512)">
            <constraints nullable="false"/>
        </column>
        <column name="file_name" type="VARCHAR(255)">
            <constraints nullable="false"/>
        </column>
    </addColumn>
</changeSet>



Met à jour ici car tu as ajouté d'autres champs dans DocumentDTO //

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
