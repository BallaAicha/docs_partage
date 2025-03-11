package com.socgen.unibank.services.autotest.model;

import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
import io.leangen.graphql.annotations.GraphQLRootContext;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/documents")
public class DocumentController {

    @Autowired
    private DocumentUploadHelper documentUploadHelper;

    @Operation(
        summary = "Create a new document with file",
        parameters = {
            @Parameter(ref = "entityIdHeader", required = true)
        }
    )
    @PostMapping(value = "/upload", consumes = "multipart/form-data")
    public DocumentDTO uploadDocument(
        @RequestParam("file") MultipartFile file,
        @RequestParam("name") String name,
        @RequestParam("description") String description,
        @RequestParam(value = "folderId", required = false) Long folderId,
        @ModelAttribute @GraphQLRootContext RequestContext context
    ) {
        return documentUploadHelper.uploadDocument(file, name, description, folderId, context);
    }
}




2. Create a DocumentUploadHelper class:


package com.socgen.unibank.services.autotest.core.usecases;

import com.socgen.unibank.domain.base.AdminUser;
import com.socgen.unibank.domain.base.DocumentStatus;
import com.socgen.unibank.platform.exceptions.TechnicalException;
import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.platform.service.s3.ObjectStorageClient;
import com.socgen.unibank.services.autotest.core.DocumentRepository;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.EntityToDTOConverter;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.FolderEntity;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.FolderRepository;
import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
import com.socgen.unibank.services.autotest.model.model.MetaDataDTO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.util.Date;
import java.util.UUID;

@Component
@Slf4j
public class DocumentUploadHelper {

    @Autowired
    private DocumentRepository documentRepository;

    @Autowired
    private FolderRepository folderRepository;

    @Autowired
    @Qualifier("privateS3Client")
    private ObjectStorageClient s3Client;

    public DocumentDTO uploadDocument(MultipartFile file, String name, String description, Long folderId, RequestContext context) {
        if (file == null || file.isEmpty()) {
            throw new TechnicalException("FILE_REQUIRED", "File is required");
        }

        if (!file.getContentType().equals("application/pdf")) {
            throw new TechnicalException("INVALID_FILE_TYPE", "Only PDF files are allowed");
        }

        try {
            String objectName = generateObjectName(file.getOriginalFilename(), context);
            
            // Upload to S3
            s3Client.upload(
                file.getInputStream(),
                objectName,
                file.getContentType()
            );

            // Create document record
            DocumentDTO newDocument = new DocumentDTO();
            newDocument.setName(name);
            newDocument.setDescription(description);
            newDocument.setStatus(DocumentStatus.CREATED);
            newDocument.setCreationDate(new Date());
            newDocument.setModificationDate(new Date());
            newDocument.setCreatedBy(new AdminUser(context.getUsername()));
            newDocument.setModifiedBy(new AdminUser(context.getUsername()));
            newDocument.setFilePath(objectName);
            newDocument.setFileName(file.getOriginalFilename());

            if (folderId != null) {
                FolderEntity folder = folderRepository.findById(folderId)
                    .orElseThrow(() -> new TechnicalException("FOLDER_NOT_FOUND", "Folder not found"));
                newDocument.setFolder(EntityToDTOConverter.convertFolderEntityToDTO(folder));
            }

            return documentRepository.saveDocument(newDocument);

        } catch (Exception e) {
            log.error("Error uploading document", e);
            throw new TechnicalException("UPLOAD_ERROR", "Error uploading document: " + e.getMessage());
        }
    }

    private String generateObjectName(String originalFilename, RequestContext context) {
        return String.format("documents/%s/%s/%s_%s",
            context.getEntityId().get().name(),
            context.getUsername(),
            UUID.randomUUID().toString(),
            originalFilename
        );
    }
}






3. Update the CreateDocument interface to remove the Command extension:

package com.socgen.unibank.services.autotest.model.usecases;

import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.services.autotest.model.model.CreateDocumentEntryRequest;
import com.socgen.unibank.services.autotest.model.model.DocumentDTO;

public interface CreateDocument {
    DocumentDTO handle(CreateDocumentEntryRequest input, RequestContext context);
}



<changeSet id="20240318-1" author="developer">
    <addColumn tableName="document">
        <column name="file_path" type="VARCHAR(512)">
            <constraints nullable="true"/>
        </column>
        <column name="file_name" type="VARCHAR(255)">
            <constraints nullable="true"/>
        </column>
    </addColumn>
</changeSet>
