Voici mon interface pour le Repository :

public interface AutoTestRepository {

}

 List<DocumentDTO> findAllDocuments();


Voici son impl :

@Component
@AllArgsConstructor
public class AutoTestRepoImpl implements AutoTestRepository {


}

    @Override
    public List<DocumentDTO> findAllDocuments() {
        return List.of();
    }


complete la logique findAllDocuments du AutoTestRepository  et complete aussi :
package com.socgen.unibank.services.autotest.core.usecases;

import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.services.autotest.model.ContentEntry;
import com.socgen.unibank.services.autotest.model.DocumentDTO;
import com.socgen.unibank.services.autotest.model.GetDocumentEntryListRequest;
import com.socgen.unibank.services.autotest.model.GetDocumentList;

import java.util.List;

public class GetDocumentListImpl implements GetDocumentList {
    @Override
    public List<DocumentDTO> handle(GetDocumentEntryListRequest input, RequestContext context) {
        List<DocumentDTO> entries;
        return List.of();
    }
}


Sachant que voici ma logique de code ::
package com.socgen.unibank.services.autotest.model;

import com.socgen.unibank.domain.base.AdminUser;
import com.socgen.unibank.domain.base.DocumentStatus;
import com.socgen.unibank.platform.domain.Domain;
import com.socgen.unibank.platform.domain.URN;
import io.leangen.graphql.annotations.GraphQLNonNull;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DocumentDTO  implements Domain {
    @GraphQLNonNull
    @NotNull
    private URN urn;
   private String name;
   private String description;
   private DocumentStatus status;
   private List<MetaDataDTO> metadata;
    private Date creationDate;
    private Date modificationDate;
    private AdminUser createdBy;
    private AdminUser modifiedBy;
}

package com.socgen.unibank.services.autotest.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MetaDataDTO {
    private String key;
    private String value;
}


package com.socgen.unibank.services.autotest.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateDocumentEntryRequest {
    private String name;
    private String description;
    private Map<String, String> metadata;
    private List<String> tags;
}

package com.socgen.unibank.services.autotest.model;

import io.swagger.v3.oas.annotations.Hidden;

@Hidden
public class GetDocumentEntryListRequest {
    public GetDocumentEntryListRequest() {
    }
}

package com.socgen.unibank.services.autotest.model;
import com.socgen.unibank.platform.domain.Query;
import com.socgen.unibank.platform.models.RequestContext;

import java.util.List;

public interface GetDocumentList  extends Query{
    List<DocumentDTO> handle(GetDocumentEntryListRequest input, RequestContext context);
}

package com.socgen.unibank.services.autotest.model;

import com.socgen.unibank.domain.business.admin.usecases.SaveBranchListRequest;
import com.socgen.unibank.platform.domain.Command;
import com.socgen.unibank.platform.models.RequestContext;

public interface CreateDocument  extends Command {
    DocumentDTO handle(CreateDocumentEntryRequest input, RequestContext context);
}


package com.socgen.unibank.services.autotest;

import com.socgen.unibank.platform.domain.Permissions;
import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.services.autotest.model.*;
import io.leangen.graphql.annotations.GraphQLQuery;
import io.leangen.graphql.annotations.GraphQLRootContext;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.security.RolesAllowed;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import java.util.List;

@Tag(name = "Content Management")
@RequestMapping(name = "content", produces = "application/json")
public interface DocumentAPI extends GetContentEntryList, TestHello , GetDocumentList , CreateDocument
    {

    @Operation(
        summary = "Fetch all content entries based on provided filter",
        parameters = {
            @Parameter(ref = "entityIdHeader", required = true),
            @Parameter(name = "type", in = ParameterIn.QUERY, schema = @Schema(implementation = ContentType.class)),
            @Parameter(name = "count", in = ParameterIn.QUERY, schema = @Schema(type = "integer"))
        }
    )
    @GetMapping(path = "entries")
    @GraphQLQuery(name = "contentEntries")
    @RolesAllowed(Permissions.IS_GUEST)
    @Override
    List<ContentEntry> handle(GetContentEntryListRequest input, @GraphQLRootContext @ModelAttribute RequestContext ctx);


        @Operation(
            summary = "test",
            parameters = {
                @Parameter(ref = "entityIdHeader", required = true),
            }
        )
        @GetMapping("/test")
        @Override
        TestHelloResponse handle(TestHelloRequest input, RequestContext context);



        @Operation(
            summary = "Fetch document list based on provided filter",
            parameters = {
                @Parameter(ref = "entityIdHeader", required = true)
            }
        )
        @GetMapping("/documents")
        @GraphQLQuery(name = "documentEntries")
        @RolesAllowed(Permissions.IS_GUEST)
        @Override
        List<DocumentDTO> handle(GetDocumentEntryListRequest input, @GraphQLRootContext @ModelAttribute RequestContext ctx);


        @Operation(
            summary = "Create a new document",
            parameters = {
                @Parameter(ref = "entityIdHeader", required = true)
            }
        )
        @PostMapping("/document")
        @GraphQLQuery(name = "createDocument")
        @RolesAllowed(Permissions.IS_GUEST)
        @Override
        DocumentDTO handle(CreateDocumentEntryRequest input, @GraphQLRootContext @ModelAttribute RequestContext ctx);

}
