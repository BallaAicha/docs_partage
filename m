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
                <constraints nullable="false"/>
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

    <!-- ChangeSet for Document Version table -->
    <changeSet id="20231001-3" author="developer">
        <createTable tableName="document_version">
            <column name="id" type="BIGINT" autoIncrement="true">
                <constraints primaryKey="true"/>
            </column>
            <column name="document_id" type="BIGINT">
                <constraints nullable="false"/>
            </column>
            <column name="version_number" type="VARCHAR(10)">
                <constraints nullable="false"/>
            </column>
            <column name="name" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
            <column name="description" type="VARCHAR(512)">
                <constraints nullable="false"/>
            </column>
            <column name="status" type="VARCHAR(50)">
                <constraints nullable="false"/>
            </column>
            <column name="file_path" type="VARCHAR(512)">
                <constraints nullable="false"/>
            </column>
            <column name="file_name" type="VARCHAR(255)">
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

    <!-- ChangeSet for Document Version Metadata table -->
    <changeSet id="20231001-4" author="developer">
        <createTable tableName="document_version_metadata">
            <column name="id" type="BIGINT" autoIncrement="true">
                <constraints primaryKey="true"/>
            </column>
            <column name="document_version_id" type="BIGINT">
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
            baseTableName="document_version_metadata"
            baseColumnNames="document_version_id"
            referencedTableName="document_version"
            referencedColumnNames="id"
            constraintName="fk_metadata_document_version"/>
    </changeSet>

    <!-- ChangeSet for Document Version Tags table -->
    <changeSet id="20231001-5" author="developer">
        <createTable tableName="document_version_tags">
            <column name="id" type="BIGINT" autoIncrement="true">
                <constraints primaryKey="true"/>
            </column>
            <column name="document_version_id" type="BIGINT">
                <constraints nullable="false"/>
            </column>
            <column name="tag" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
        </createTable>

        <addForeignKeyConstraint
            baseTableName="document_version_tags"
            baseColumnNames="document_version_id"
            referencedTableName="document_version"
            referencedColumnNames="id"
            constraintName="fk_tags_document_version"/>
    </changeSet>
</databaseChangeLog>





——————————————————


@Entity
@Table(name = "document")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DocumentEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DocumentStatus status;

    @ManyToOne
    @JoinColumn(name = "folder_id")
    private FolderEntity folder;

    @OneToMany(mappedBy = "document", cascade = CascadeType.ALL)
    private List<DocumentVersionEntity> versions;

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
}

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
    private String versionNumber;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DocumentStatus status;

    @Column(nullable = false)
    private String filePath;

    @Column(nullable = false)
    private String fileName;

    @OneToMany(mappedBy = "documentVersion", cascade = CascadeType.ALL)
    private List<DocumentVersionMetadataEntity> metadata;

    @OneToMany(mappedBy = "documentVersion", cascade = CascadeType.ALL)
    private List<DocumentVersionTagEntity> tags;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "creation_date", nullable = false)
    private Date creationDate;

    @Column(nullable = false)
    private String createdBy;
}





—————————————————————
@Component
@Slf4j
public class DocumentUploadHelper {

    @Autowired
    private DocumentRepository documentRepository;

    @Autowired
    private DocumentVersionRepository documentVersionRepository;

    @Autowired
    @Qualifier("privateS3Client")
    private ObjectStorageClient s3Client;

    public DocumentVersionDTO uploadDocumentVersion(MultipartFile file, CreateDocumentVersionRequest input, RequestContext context) {
        validateFile(file);

        try {
            // Générer un nom unique pour le fichier version
            String versionFileName = generateVersionFileName(file.getOriginalFilename(), input.getVersionNumber());
            String objectName = generateObjectName(versionFileName);

            // Upload to S3
            s3Client.upload(
                file.getInputStream(),
                "documents",
                objectName,
                file.getContentType()
            );

            // Créer la version du document
            DocumentVersionDTO version = createDocumentVersionDTO(input, file, objectName, context);
            return documentVersionRepository.saveDocumentVersion(version);

        } catch (Exception e) {
            log.error("Error uploading document version: {}", e.getMessage(), e);
            throw new IllegalArgumentException("Error uploading document version: " + e.getMessage());
        }
    }

    private String generateVersionFileName(String originalFilename, String versionNumber) {
        String baseName = FilenameUtils.getBaseName(originalFilename);
        String extension = FilenameUtils.getExtension(originalFilename);
        return String.format("%s_v%s.%s", baseName, versionNumber, extension);
    }

    private String generateObjectName(String versionFileName) {
        return String.format("documents/%s/%s",
            UUID.randomUUID().toString(),
            versionFileName
        );
    }

    private DocumentVersionDTO createDocumentVersionDTO(CreateDocumentVersionRequest input, MultipartFile file, String objectName, RequestContext context) {
        DocumentVersionDTO version = new DocumentVersionDTO();
        version.setDocumentId(input.getDocumentId());
        version.setVersionNumber(input.getVersionNumber());
        version.setName(input.getName());
        version.setDescription(input.getDescription());
        version.setStatus(input.getStatus());
        version.setFilePath(objectName);
        version.setFileName(file.getOriginalFilename());
        version.setCreationDate(new Date());
        version.setCreatedBy(context.getUsername());
        version.setMetadata(input.getMetadata());
        version.setTags(input.getTags());
        
        return version;
    }

    private void validateFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("File is null or empty");
        }

        if (!file.getContentType().equals("application/pdf")) {
            throw new IllegalArgumentException("Invalid file type. Only PDF files are allowed");
        }
    }
}



—————
@RestController
@RequestMapping("/documents")
public class DocumentController {

    @Autowired
    private DocumentUploadHelper documentUploadHelper;

    @Operation(
        summary = "Upload a new document version",
        parameters = {
            @Parameter(ref = "entityIdHeader", required = true)
        }
    )
    @PostMapping(value = "/{documentId}/versions", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public DocumentVersionDTO uploadDocumentVersion(
        @PathVariable Long documentId,
        @RequestParam("file") MultipartFile file,
        @RequestParam("name") String name,
        @RequestParam("description") String description,
        @RequestParam("versionNumber") String versionNumber,
        @RequestParam("status") DocumentStatus status,
        @RequestParam(value = "tags", required = false) List<String> tags,
        @RequestParam(value = "metadata", required = false) Map<String, String> metadata,
        @ModelAttribute @GraphQLRootContext RequestContext context
    ) {
        CreateDocumentVersionRequest request = new CreateDocumentVersionRequest();
        request.setDocumentId(documentId);
        request.setName(name);
        request.setDescription(description);
        request.setVersionNumber(versionNumber);
        request.setStatus(status);
        request.setTags(tags != null ? tags : new ArrayList<>());
        request.setMetadata(metadata != null ? metadata : new HashMap<>());

        return documentUploadHelper.uploadDocumentVersion(file, request, context);
    }
}
